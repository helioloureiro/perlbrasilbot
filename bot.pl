#! /usr/bin/perl -w
#
#
use WWW::Telegram::BotAPI;
use Mojo::IOLoop;

my $token = $ENV{'TELEGRAMBOTTOKEN'};

if (! defined($token)) {
    die "Faltando configuração do token de autenticação";
}

my $api = WWW::Telegram::BotAPI->new (
    token => $token
);

# The API methods die when an error occurs.
print "Bot name:".$api->getMe->{result}{username}."\n";
# ... but error handling is available as well.
my $result = eval { $api->getMe }
    or die 'Got error message: ', $api->parse_error->{msg};
print $api->getUpdates->{result}."\n";
print $api->getChat({chat_id => '@perlbrasil'})."\n";
$api->sendMessage ({
    chat_id      => '@perlbrasil', 
    text => "Chupa essa manga!"
});



Mojo::IOLoop->start;
