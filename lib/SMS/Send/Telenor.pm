package SMS::Send::Telenor;
use HTTP::Tiny;
use strict;
use warnings;
our $VERSION = '0.05';
use base 'SMS::Send::Driver';

sub new {
    my ($class, @arg_arr) = @_;
    my $args = {
        _login      => "$arg_arr[1]",
        _password   => "$arg_arr[3]"
    };

    die "$class needs hash_ref with _login and password.\n" unless $args->{_login} && $args->{_password};
    my $self = bless {%$args}, $class;
    $self->{send_url} = 'http://sms-pro.net/services/' . $args->{_login} . '/sendsms';
    $self->{status_url} = 'http://sms-pro.net/services/' . $args->{_login} . '/status';
    $self->{sms_sender} = 'FROM SENDER'; #Add the text that describes who sent the sms
    return $self;
}

sub send_sms {
    my ($self, @arg_arr) = @_;
    my $args = {
        customer_id     => "$self->{_login}",
        password        => "$self->{_password}",
        message         => "$arg_arr[1]",
        to_msisdn       => "$arg_arr[3]",
        sms_sender      => "$self->{sms_sender}"
    };

    my $sms_xml = _build_sms_xml($args);
    my $response = _post($self->{send_url}, $sms_xml);

    my $rv = 1;
    if (defined $response) {
        $rv = _verify_response("$response->{content}");
    }
    return 1 if $rv eq '0';
    return 0;
}

# This status subroutine is not used by SMS::Send but can be used directly with the driver.
sub sms_status {
    my ($self, $mobilectrl_id) = @_;
    my $args = {
        customer_id     => "$self->{_login}",
        mobilectrl_id   => "$mobilectrl_id"
    };
    my $xml = _build_status_xml($args);
    return _post($self->{status_url}, $xml);
}

sub _post {
    my ($url, $sms_xml) = @_;
    return HTTP::Tiny->new->post(
        $url => {
            content => $sms_xml,
            headers => {
                "Content-Type" => "application/xml",
            },
        },
    );
}

sub _build_sms_xml {
    my $args = shift;
    return '<?xml version="1.0" encoding="ISO-8859-1"?>'
    . '<mobilectrl_sms>'
    . '<header>'
    . '<customer_id>'
    . $args->{customer_id}
    . '</customer_id>'
    . '<password>'
    . $args->{password}
    . '</password>'
    . '<from_alphanumeric>'
    . $args->{sms_sender}
    . '</from_alphanumeric>'
    . '</header>'
    . '<payload>'
    . '<sms account="71700">'
    . '<message><![CDATA['
    . $args->{message}
    . ']]></message>'
    . '<to_msisdn>'
    . $args->{to_msisdn}
    . '</to_msisdn>'
    . '</sms>'
    . '</payload>'
    . '</mobilectrl_sms>';
}

sub _build_status_xml {
    my $args = shift;
    return '<?xml version="1.0" encoding="ISO-8859-1"?>'
    . '<mobilectrl_delivery_status_request>'
    . '<customer_id>'
    . $args->{customer_id}
    . '</customer_id>'
    . '<status_for type="mobilectrl_id">'
    . $args->{mobilectrl_id}
    . '</status_for>'
    . '</mobilectrl_delivery_status_request>';
}

sub _verify_response {
    my $content = shift;
    if ($content =~ /\<status\>(\d)\<\/status>/) {
        return $1;
    }
    return 1;
}
1;

=head1 NAME

SMS::Send::Telenor - SMS::Send driver to send messages via Telenor SMS Pro

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new('Telenor',
        _login    => 'your_aql_username',
        _password => 'your_aql_password',
  );

  # Send a message
  my $sent = $sender->send_sms(
        text => 'This is a test message',
        to   => '+4612345678',
  );

  if ( $sent ) {
        print "Message sent ok\n";
  } else {
        print "Failed to send message\n";
  }


=head1 DESCRIPTION

A driver for SMS::Send to send SMS text messages via Telenor SMS Pro API

This is not intended to be used directly, but instead called by SMS::Send
(see synopsis above for a basic illustration, and see SMS::Send's documentation
for further information).


=head1 AUTHOR

Eivin Giske Skaaren, <lt>eivin@sysmystic.com<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015  by Eivin Giske Skaaren

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
__END__
