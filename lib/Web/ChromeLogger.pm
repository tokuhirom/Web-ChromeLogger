package Web::ChromeLogger;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use JSON::XS;
use MIME::Base64;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $self  = bless {
        %args
    }, $class;
    $self->{'json_encoder'} ||= JSON::XS->new()->ascii(1)->convert_blessed;
    $self->{'logs'} = [];
    return $self;
}

sub json_encoder { $_[0]->{json_encoder} }

sub group {
    my $self = shift;
    $self->push_log('group', @_);
}

sub group_end {
    my $self = shift;
    $self->push_log('groupEnd', @_);
}

sub group_collapsed {
    my $self = shift;
    $self->push_log('groupCollapsed', @_);
}

sub info {
    my $self = shift;
    $self->push_log('info', @_);
}

sub warn {
    my $self = shift;
    $self->push_log('warn', @_);
}

sub error {
    my $self = shift;
    $self->push_log('error', @_);
}

# User can overwrite this method in child class.
sub to_json {
    my ($self, $stuff) = @_;
    "$stuff"
}

sub encode {
    my ($self, $rows) = @_;

    no warnings 'once';
    local *UNIVERSAL::TO_JSON = sub { $self->to_json(@_) };
    my $json_data = $self->json_encoder->encode(
        {
            "version" => "0.2",
            "columns" => [ "log", "backtrace", "type" ],
            "rows"    => $rows,
        },
    );
    my $mime_data = MIME::Base64::encode_base64($json_data);
    $mime_data =~ s/\n/''/g;

    return $mime_data;
}

sub wrap_by_group {
    my ($self, $title) = @_;
    $self->unshift_log('group', $title);
    $self->push_log('groupEnd', $title);
}

sub push_log {
    my $self = shift;
    push @{ $self->{logs} }, [ [ $_[1] ], $_[2], $_[0] ];
}

sub unshift_log {
    my $self = shift;
    unshift @{ $self->{logs} }, [ [ $_[1] ], $_[2], $_[0] ];
}

sub finalize {
    my ($self) = @_;
    $self->encode($self->{logs});
}

1;
__END__

=encoding utf-8

=head1 NAME

Web::ChromeLogger - ChromeLogger for Perl

=head1 SYNOPSIS

    use Web::ChromeLogger;

    get '/', sub {
        my $logger = Web::ChromeLogger->new();
        $logger->info('hey!');

        my $html = render_html();

        return [
            200,
            ['X-ChromeLogger-Data' => $logger->finalize()],
            $html,
        ];
    };

=head1 DESCRIPTION

Web::ChromeLogger is a ChromeLogger library for Perl5.

Chrome Logger is a Google Chrome extension for debugging server side applications in the Chrome console.

=head1 HOW IT WORKS

This module generates the string for ChromeLogger. You can send the string in 'X-ChromeLogger-Data' header in HTTP response.

For more details, please see L<ChromeLogger's Technical Specification|http://craig.is/writing/chrome-logger/techspecs>

=head1 LARGE RESPONSE HEADER

=head2 NGINX PROXY

If you are using nginx as reverse proxy, you may need to set following parameters in your configuration file:

    proxy_buffer_size   128k;
    proxy_buffers   4 256k;
    proxy_busy_buffers_size   256k;

=head2 Maximum Data Size

Chrome has a limit of C<250kb> across all headers for a single request so that is the maximum amount of encoded data you can send.

=head1 METHODS

=over 4

=item C<< my $logger = Web::ChromeLogger->new(%args) >>

Create new instance with following parameters:

=over 4

=item json_encoder (Default: C<< JSON::XS->new()->ascii(1)->convert_blessed >> )

JSON encoder object. You can use JSON::XS or JSON::PP for this.

I guess you don't need to set this parameter.

=back

=item C<< $logger->group($title: Str) >>

Push C<group>.

=item C<< $logger->group_end($title: Str) >>

Push C<groupEnd>.

=item C<< $logger->info($title: Str) >>

Push C<info>.

=item C<< $logger->warn($title: Str) >>

Push C<warn>.

=item C<< $logger->wrap_by_group($title: Str) >>

Wrap current logging data by C<$title> group.

=item C<< $logger->finalize() >>

Generate header string.

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<ChromeLogger|http://craig.is/writing/chrome-logger>

=cut

