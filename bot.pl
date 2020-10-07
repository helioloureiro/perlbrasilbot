#! /usr/bin/perl -w
#
#
use WWW::Telegram::BotAPI;
use utf8;

my $token = $ENV{'TELEGRAMBOTTOKEN'};

if (! defined($token)) {
    die "Faltando configuração do token de autenticação";
}

my $api = WWW::Telegram::BotAPI->new (
    token => $token
);

# Copied from: https://gist.github.com/Robertof/d9358b80d95850e2eb34

my $me = $api->getMe or die;
my ($offset, $updates) = 0;

# The commands that this bot supports.
my $pic_id; # file_id of the last sent picture
my $commands = {
    # Example demonstrating the use of parameters in a command.
    "diga"      => sub { join " ", splice @_, 1 or "Uso: /diga alguma coisa" },
    # Example showing how to use the result of an API call.
    "quemsoueu"   => sub {
        sprintf "Oi %s, eu sou %s! Como você está?", shift->{from}{username}, $me->{result}{username}
    },
    # Example showing how to send multiple lines in a single message.
    "knock"    => sub {
        sprintf "Knock-knock.\n- Abre a porta Mariquinha?\n@%s!", $me->{result}{username}
    },
    # Example displaying a keyboard with some simple options.
    "teclado" => sub {
        +{
            text => "Olha aqui um teclado maneirasso.",
            reply_markup => {
                keyboard => [ [ "a" .. "c" ], [ "d" .. "f" ], [ "g" .. "i" ] ],
                one_time_keyboard => \1 # \1 maps to "true" when being JSON-ified
            }
        }
    },
    # Let me identify yourself by sending your phone number to me.
    "telefone" => sub {
        +{
            text => "Você quer me passar seu telefone?",
            reply_markup => {
                keyboard => [
                    [
                        {
                            text => "Belê!",
                            request_contact => \1
                        },
                        "Não, sai fora!"
                    ]
                ],
                one_time_keyboard => \1
            }
        }
    },
    # Test UTF-8
    "encoding" => sub { "Привет! こんにちは! Buondì!" },
    # Example sending a photo with a known picture ID.
    "ultimafoto" => sub {
        return "Você não enviou nenhuma foto!" unless $pic_id;
        +{
            method  => "sendPhoto",
            photo   => $pic_id,
            caption => "Olha ela aqui!"
        }
    },
    "_unknown" => "Comando desconhecido :( Tente /start"
};

# Generate the command list dynamically.
$commands->{start} = "Oi! Tente /" . join " - /", grep !/^_/, keys %$commands;

# Special message type handling
my $message_types = {
    # Save the picture ID to use it in `lastphoto`.
    "photo" => sub { $pic_id = shift->{photo}[0]{file_id} },
    # Receive contacts!
    "contact" => sub {
        my $contact = shift->{contact};
        +{
            method     => "sendMessage",
            parse_mode => "Markdown",
            text       => sprintf (
                            "Aqui estão as informações de contacto.\n" .
                            "- Nome: *%s*\n- Sobrenome: *%s*\n" .
                            "- Númber de telefone: *%s*\n- Telegram UID: *%s*",
                            $contact->{first_name}, $contact->{last_name} || "?",
                            $contact->{phone_number}, $contact->{user_id} || "?"
                        )
        }
    }
};

printf "Kawabanga!  Eu sou %s. Inicializando...\n", $me->{result}{username};

while (1) {
    $updates = $api->getUpdates ({
        timeout => 30, # Use long polling
        $offset ? (offset => $offset) : ()
    });
    unless ($updates and ref $updates eq "HASH" and $updates->{ok}) {
        warn "AVISO: getUpdates returnou um valor falso - tentando novamente...";
        next;
    }
    for my $u (@{$updates->{result}}) {
        $offset = $u->{update_id} + 1 if $u->{update_id} >= $offset;
        if (my $text = $u->{message}{text}) { # Text message
            printf "Chegando mensagem de texto de \@%s\n", $u->{message}{from}{username};
            printf "Texto: %s\n", $text;
            next if $text !~ m!^/[^_].!; # Not a command
            my ($cmd, @params) = split / /, $text;
            my $res = $commands->{substr ($cmd, 1)} || $commands->{_unknown};
            # Pass to the subroutine the message object, and the parameters passed to the cmd.
            $res = $res->($u->{message}, @params) if ref $res eq "CODE";
            next unless $res;
            my $method = ref $res && $res->{method} ? delete $res->{method} : "sendMessage";
            print "Method: $method\n";
            print "res: $res\n";
            eval {
                $api->$method ({
                    chat_id => $u->{message}{chat}{id},
                    ref $res ? %$res : ( text => $res )
                });
                print "Resposta enviada.\n";
            } or do {
                print "Erro ao responder ".$method
                ." com a mensagem ".$res
                ." para ".$u->{message}{from}{username}
                ."\n";
            }
        }
        # Handle other message types.
        for my $type (keys %{$u->{message} || {}}) {
            # ;
            next unless exists $message_types->{$type} and
                ref (my $res2 = $message_types->{$type}->($u->{message}));
            my $method2 = delete ($res2->{method}) || "sendMessage";
            eval {
                $api->$method2 ({
                    chat_id => $u->{message}{chat}{id},
                    %$res2
                });
            } or do {
                print "Erro ao enviar ".$method2."\n";
            }
        }
    }
}
