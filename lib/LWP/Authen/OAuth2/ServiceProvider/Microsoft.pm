package LWP::Authen::OAuth2::ServiceProvider::Microsoft;

# ABSTRACT: Microsoft Azure AD "Application" OAuth
our $VERSION = 'v0.0.0'; # VERSION conforming to Semantic versioning

use strict;
use warnings;

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);

my $tenant = '';

# For the curious, the following sub is here to take the tenant option and stash
# it locally for when authorization_endpoint and token_endpoint are called
sub collect_action_params {
  my $self = shift;
  my $action = shift;
  my $oauth2 = shift;
  my $oauth2_args = $oauth2->for_service_provider;
  my $opt = {@_};
  if (exists $opt->{tenant}) {
    $tenant = $opt->{tenant};
  } else {
    $tenant = $oauth2_args->{tenant};
  }
  return $self->SUPER::collect_action_params($action, $oauth2, @_);
}
sub authorization_endpoint {
  if (!$tenant) { return ''; }
  return "https://login.microsoftonline.com/$tenant/oauth2/authorize";
}

sub token_endpoint {
  if (!$tenant) { return ''; }
  return "https://login.microsoftonline.com/$tenant/oauth2/token";
}

sub required_init {
  my $self = shift;
  return ("tenant", $self->SUPER::required_init());
}
sub authorization_required_params {
    my $self = shift;
    return ("client_id", "redirect_uri", "response_mode", "response_type", "scope", $self->SUPER::authorization_required_params());
}

sub authorization_optional_params {
    my $self = shift;
    return ("prompt", $self->SUPER::authorization_optional_params());
}

sub authorization_default_params {
  my $self = shift;
  return (
    "scope" => "User.Read",
    "response_mode" => "query",
    "response_type" => "code",
    $self->SUPER::authorization_default_params()
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Microsoft - Microsoft Azure AD
(login.microsoftonline.com) authentication with OAuth2

=head1 VERSION

Version v0.0.0

=head1 SYNOPSIS

Authentication module for Microsoft's OAuth2 backend to Azure. There a lot of
documentation on Microsoft's websites, but good luck...

Probably the best place to start is
https://docs.microsoft.com/en-us/azure/active-directory/develop/reference-v2-libraries,
which has many implemented libraries (none in perl) to look through.

This module ONLY deals with the authentication; in order to query the
resulting tokens for the details of who logged in, you'll need to
implement some more code (see EXAMPLES below).

=head1 INSTALLATION

C<cpan install LWP::Authen::OAuth2::ServiceProvider::Microsoft>

=head1 USAGE

In order to use this module you'll need the following information for your Azure AD:

=over 1

=item *

B<Your tenant ID>. Also known as Directory ID in Azure. This is used as part of the
authentication URL: https://login.microsoftonline.com/<tenant>/oauth2/authorize

=item *

B<Your client ID>. Also known as application ID in Azure.

=item *

B<Your client Secret>, created from the "client credentials" section of the
Application overview

=item *

B<A return URI>. This needs to be registered with Microsoft - you can't return to
an arbitrary place.

=item *

Optionally you'll need to define the scopes required by the authentication
token; this is required when you intend to actually do something with the token,
such as access account information, emails, sharepoint etc. through the
Microsoft Graph API.

=back

The "prompt" parameter is also supported:

  my $oauth2 = LWP::Authen::OAuth2->new(
    ...
    prompt => "login",  # Add this to new(...) to force Microsoft to show the log in prompt, even if the user is already logged in
  );

=head2 EXAMPLES

=head3 Adding authentication to a web app

The following example is called "auth.cgi", stored in a local machine document
root accessed with C<http://localhost/auth.cgi>.

  #!/usr/bin/perl

  use LWP::Authen::OAuth2;
  use CGI;
  use JSON;
  use MIME::Base64;

  my $cgi = new CGI;
  my $code = $cgi->param('code');

  # Create the OAuth2 object
  my $oauth2 = LWP::Authen::OAuth2->new(
    client_id => '(your-client-id)',
    client_secret => '(your-client-secret)',
    tenant => '(your-tenant)',
    service_provider => "Microsoft",
    redirect_uri => "http://localhost/auth.cgi",
    scope => "User.Read User.ReadBasic.All Files.Read.All",
  );

  # Check to see if we're returning from the authentication. If so,
  # CGI parameter "code" will be provided. If there's no "code"
  # we'll redirect the web browser to the authentication URL
  if (!$code) {
    my $url = $oauth2->authorization_url();
    print "Location: $url\n\n";
    exit;
  }

  # We have a code! Great! Let's continue...
  $oauth2->request_tokens(code => $code);

  my $complete = $oauth2->token_string;
  my $tokendata = {};
  eval {
    $tokendata = decode_json($complete);
  };
  if ($@ || !defined $tokendata->{id_token}) { die "Token isn't the expected JSON object\n$complete"; }
  # Microsoft returns some information about the user in the token
  my @seg = split(/\./, $tokendata->{id_token});
  my $dec = decode_base64($seg[1]);
  my $userdata = {};
  eval {
    $userdata = decode_json($dec);
  };
  if ($@) { die "Couldn't decode user data from the token"; }

  # Do something meaningful with $userdata hashref, redirect the browser to another page
  # For this example, we'll just print who logged in
  print "Content-type: text/plain\n\n";
  print "Logged in user: $userdata->{unique_name}\n";

=head3 Adding authentication to a command line script

The following example is for a perl script run on a command line that requires
authentication via a web browser. Note in particular that the redirect_uri is
different; this must also be added to your Application Redirect URIs list,
but I don't need a web server.

  #!/usr/bin/perl

  use LWP::Authen::OAuth2;
  use JSON;
  use MIME::Base64;

  my $oauth2 = LWP::Authen::OAuth2->new(
    client_id => '(your-client-id)',
    client_secret => '(your-client-secret)',
    tenant => '(your-tenant)',
    service_provider => "Microsoft",
    redirect_uri => "https://login.microsoftonline.com/common/oauth2/nativeclient",
    scope => "User.Read"
  );

  print "1. Copy and paste this URL into a web browser.\n";
  print $oauth2->authorization_url();
  print "\n\n2. Once you've logged in, copy and paste the URL from your web browser back here.\nEnter URL returned: ";
  my $url = <STDIN>;
  my ($code) = $url =~ /code=([^&]+)/;
  if (!$code) {
    die "Error: Couldn't find the code in the response URL\n";
  }

  # We have a code! Great! Let's continue...
  $oauth2->request_tokens(code => $code);

  my $complete = $oauth2->token_string;
  my $tokendata = {};
  eval {
    $tokendata = decode_json($complete);
  };
  if ($@ || !defined $tokendata->{id_token}) { die "Token isn't the expected JSON object\n$complete"; }
  # Microsoft returns some information about the user in the token
  my @seg = split(/\./, $tokendata->{id_token});
  my $dec = decode_base64($seg[1]);
  my $userdata = {};
  eval {
    $userdata = decode_json($dec);
  };
  if ($@) { die "Couldn't decode user data from the token"; }

  # Do something meaningful with $userdata hashref
  print "Logged in user was $userdata->{unique_name}\n";

=head1 AUTHORS

=over 4

=item *

Pero Moretti <pero.g.moretti at gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is (c) 2022 by Pero Moretti.

This is free software licensed under FreeBSD. Please see the LICENSE file for more information.

=cut
