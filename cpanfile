requires 'JSON';
requires 'WWW::Telegram::BotAPI';
requires 'Sys::Syslog';

recommends 'Cpanel::JSON::XS';

on 'test' => sub {
  requires 'Test::More';
};

on 'develop' => sub {
  recommends 'Perl::Tidy', '>= 20210111';
};
