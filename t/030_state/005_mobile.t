use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTTP::Session;
use HTTP::Session::Store::Test;
use CGI;
plan skip_all => "this test requires HTTP::MobileAttribute, Net::CIDR::MobileJP" unless eval "use HTTP::MobileAttribute; use Net::CIDR::MobileJP; 1;";
plan skip_all => "this test requires HTTP::MobileAttribute 0.11 or later" unless eval "\$HTTP::MobileAttribute::VERSION >= 0.11 ? 1 : 0";
plan tests => 5;
require HTTP::Session::State::MobileAttributeID;
use HTTP::Response;

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa'
    );
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::MobileAttributeID->new(
            mobile_attribute => HTTP::MobileAttribute->new(),
            check_ip => 0,
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    is $session->session_id(), 'fooobaa', 'permissive';
    my $res = HTTP::Response->new();
    $session->response_filter($res); # nop.
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa',
        REMOTE_ADDR     => '210.153.84.1',
    );
    my $session = HTTP::Session->new(
        state => HTTP::Session::State::MobileAttributeID->new(
            mobile_attribute => HTTP::MobileAttribute->new(),
        ),
        store   => HTTP::Session::Store::Test->new(),
        request => CGI->new(),
    );
    is $session->session_id(), 'fooobaa', 'permissive';
    my $res = HTTP::Response->new();
    $session->response_filter($res); # nop.
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
        HTTP_X_DCMGUID  => 'fooobaa',
        REMOTE_ADDR     => '192.168.1.1',
    );
    throws_ok {
        HTTP::Session->new(
            state => HTTP::Session::State::MobileAttributeID->new(
                mobile_attribute => HTTP::MobileAttribute->new(),
            ),
            store   => HTTP::Session::Store::Test->new(),
            request => CGI->new(),
        )
    } qr/invalid ip\(192\.168\.1\.1, HTTP::MobileAttribute::Agent::DoCoMo=HASH\(0x[a-z0-9]+\), fooobaa\)/;
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'DoCoMo/1.0/D504i/c10/TJ',
    );
    my $state = HTTP::Session::State::MobileAttributeID->new(
        mobile_attribute => HTTP::MobileAttribute->new()
    );
    throws_ok { $state->get_session_id() } qr/cannot detect mobile id/;
}->();

sub {
    local %ENV = (
        HTTP_USER_AGENT => 'MOZILLA',
    );
    my $state = HTTP::Session::State::MobileAttributeID->new(
        mobile_attribute => HTTP::MobileAttribute->new()
    );
    throws_ok { $state->get_session_id() } qr/this carrier doesn't supports user_id/;
}->();
