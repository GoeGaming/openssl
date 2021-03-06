#! /usr/bin/perl

use strict;
use warnings;

use POSIX;
use File::Spec::Functions qw/devnull catfile/;
use File::Copy;
use OpenSSL::Test qw/:DEFAULT with pipe top_dir/;

setup("test_ocsp");

my $ocspdir=top_dir("test", "ocsp-tests");
# 17 December 2012 so we don't get certificate expiry errors.
my @check_time=("-attime", "1355875200");

sub test_ocsp {
    my $title = shift;
    my $inputfile = shift;
    my $CAfile = shift;
    my $expected_exit = shift;

    with({ exit_checker => sub { return shift == $expected_exit; } },
	 sub { ok(run(pipe(app(["openssl", "base64", "-d",
				"-in", catfile($ocspdir,$inputfile)]),
			   app(["openssl", "ocsp", "-respin", "-",
				"-partial_chain", @check_time,
				"-CAfile", catfile($ocspdir, $CAfile),
				"-verify_other", catfile($ocspdir, $CAfile),
				"-CApath", devnull()]))),
		  $title); });
}

plan tests => 10;

subtest "=== VALID OCSP RESPONSES ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "ND1.ors", "ND1_Issuer_ICA.pem", 0);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "ND2.ors", "ND2_Issuer_Root.pem", 0);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "ND3.ors", "ND3_Issuer_Root.pem", 0);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "D1.ors", "D1_Issuer_ICA.pem", 0);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "D2.ors", "D2_Issuer_Root.pem", 0);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "D3.ors", "D3_Issuer_Root.pem", 0);
};

subtest "=== INVALID SIGNATURE on the OCSP RESPONSE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "ISOP_ND1.ors", "ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "ISOP_ND2.ors", "ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "ISOP_ND3.ors", "ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "ISOP_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "ISOP_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "ISOP_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG RESPONDERID in the OCSP RESPONSE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "WRID_ND1.ors", "ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "WRID_ND2.ors", "ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "WRID_ND3.ors", "ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "WRID_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "WRID_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "WRID_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG ISSUERNAMEHASH in the OCSP RESPONSE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "WINH_ND1.ors", "ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "WINH_ND2.ors", "ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "WINH_ND3.ors", "ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "WINH_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "WINH_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "WINH_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG ISSUERKEYHASH in the OCSP RESPONSE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "WIKH_ND1.ors", "ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "WIKH_ND2.ors", "ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "WIKH_ND3.ors", "ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "WIKH_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "WIKH_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "WIKH_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG KEY in the DELEGATED OCSP SIGNING CERTIFICATE ===" => sub {
    plan tests => 3;

    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "WKDOSC_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "WKDOSC_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "WKDOSC_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== INVALID SIGNATURE on the DELEGATED OCSP SIGNING CERTIFICATE ===" => sub {
    plan tests => 3;

    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "ISDOSC_D1.ors", "D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "ISDOSC_D2.ors", "D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "ISDOSC_D3.ors", "D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG SUBJECT NAME in the ISSUER CERTIFICATE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "ND1.ors", "WSNIC_ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "ND2.ors", "WSNIC_ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "ND3.ors", "WSNIC_ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "D1.ors", "WSNIC_D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "D2.ors", "WSNIC_D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "D3.ors", "WSNIC_D3_Issuer_Root.pem", 1);
};

subtest "=== WRONG KEY in the ISSUER CERTIFICATE ===" => sub {
    plan tests => 6;

    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "ND1.ors", "WKIC_ND1_Issuer_ICA.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "ND2.ors", "WKIC_ND2_Issuer_Root.pem", 1);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "ND3.ors", "WKIC_ND3_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "D1.ors", "WKIC_D1_Issuer_ICA.pem", 1);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "D2.ors", "WKIC_D2_Issuer_Root.pem", 1);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "D3.ors", "WKIC_D3_Issuer_Root.pem", 1);
};

subtest "=== INVALID SIGNATURE on the ISSUER CERTIFICATE ===" => sub {
    plan tests => 6;

    # Expect success, because we're explicitly trusting the issuer certificate.
    test_ocsp("NON-DELEGATED; Intermediate CA -> EE",
	      "ND1.ors", "ISIC_ND1_Issuer_ICA.pem", 0);
    test_ocsp("NON-DELEGATED; Root CA -> Intermediate CA",
	      "ND2.ors", "ISIC_ND2_Issuer_Root.pem", 0);
    test_ocsp("NON-DELEGATED; Root CA -> EE",
	      "ND3.ors", "ISIC_ND3_Issuer_Root.pem", 0);
    test_ocsp("DELEGATED; Intermediate CA -> EE",
	      "D1.ors", "ISIC_D1_Issuer_ICA.pem", 0);
    test_ocsp("DELEGATED; Root CA -> Intermediate CA",
	      "D2.ors", "ISIC_D2_Issuer_Root.pem", 0);
    test_ocsp("DELEGATED; Root CA -> EE",
	      "D3.ors", "ISIC_D3_Issuer_Root.pem", 0);
};
