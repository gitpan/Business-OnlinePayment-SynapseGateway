package Business::OnlinePayment::SynapseGateway;


use strict;
use warnings;
use Carp;
use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION @ISA $me);

@ISA = qw(Business::OnlinePayment::HTTPS);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::OnlinePayment::SynapseGateway ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';
$me = 'Business::OnlinePayment::SynapseGateway';

sub set_defaults {
    my $self = shift;
	print "Setting defaults...\n";
    $self->server('connect.synapsegateway.net');
    $self->path('/Submit');    
	
    $self->build_subs(qw( order_number avs_code                           
		      ));
}

sub map_fields {
    my($self) = @_;

    my %content = $self->content();
    print "Mapping fields...\n";
    #my $avs = $self->require_avs;
    #$avs = 1 unless defined($avs) && length($avs); #default AVS on unless explicitly turned off

    my %map;
    if (
      $content{'type'} =~ /^(cc)$/i
    ) {
 
        %map = ( 'normal authorization' => 'S',
                 'authorization only'   => 'A',
                 'credit'               => 'C',
                 'post authorization'   => 'P',
                 'void'                 => 'V',
               );   
    }

    $content{'type'} = $map{lc($content{'action'})}
      or croak 'Unknown action: '. $content{'action'};

    $self->transaction_type($content{'type'});

    # stuff it back into %content
    $self->content(%content);
}

sub submit {
    my($self) = @_;
    print "Submitting...\n";
	$self->map_fields();
	$self->remap_fields(
	
	    login            => 'Syn_Act',
        password         => 'Syn_Pwd',
		action           => 'Tran_Type',
		amount			 => 'Tran_Amt',
		invoice_number	 => 'Tran_Inv',
		customer_id      => 'Tran_CNum',
		description      => 'Tran_Note',
		card_number      => 'Card_Num',
		name             => 'Card_Name',
		expiration       => 'Card_Exp',
		address          => 'AVS_Street',
		zip              => 'AVS_Zip',
		cvv2             => 'CVV_Num',	
		order_number	 => 'Proc_ID',
    );
	
	$self->required_fields();
	
	my( $page, $response, %reply_headers) =
      $self->https_post( $self->get_fields( $self->fields ) );
	print "Getting response...\n";
    my $echotype1 = $self->GetEchoReturn($page, 1);
    my $echotype2 = $self->GetEchoReturn($page, 2);
    my $echotype3 = $self->GetEchoReturn($page, 3);
    my $openecho  = $self->GetEchoReturn($page, 'OPEN');
	
	$self->server_response($page);
    $self->authorization( $self->GetEchoProp($echotype3, 'Proc_Code') );
    $self->order_number(  $self->GetEchoProp($echotype3, 'Proc_ID') );
	$self->result_code(   $self->GetEchoProp($echotype3, 'Proc_Resp') );
    $self->avs_code(      $self->GetEchoProp($echotype3, 'AVS_Code') );
	
	if ($self->result_code =~ /^[A]$/ ) { #success     
      $self->is_success(1);   

    } else {
      $self->is_success(0);

      my $decline_code = $self->GetEchoProp($echotype3, 'Proc_Mess');
      #my $error_message = $self->error($decline_code);
      #if ( $decline_code =~ /^(00)?30$/ ) {
      # $echotype2 =~ s/<br>/\n/ig;
      #$echotype2 =~ s'</?(b|pre)>''ig;
      # $error_message .= ": $echotype2";
      #}
      $self->error_message( $decline_code );
    }
    $self->is_success(0) if $page eq '';	
}

sub fields {
	my $self = shift;
        print "fields...\n";
	my @fields = qw(
	  Syn_Act
	  Syn_Pwd
	  Tran_Type
	  Tran_Amt
	  Tran_Inv
	  Tran_CNum
	  Tran_Note
	  Card_Num
	  Card_Name
	  Card_Exp
	  AVS_Street
	  AVS_Zip
	  CVV_Num
	  Proc_ID
	);

	push @fields, qw(
	  grand_total
	  merchant_email
	  merchant_trace_nbr
	  original_amount
	  original_trandate_mm
	  original_trandate_dd
	  original_trandate_yyyy
	  original_reference
	  order_number
	  shipping_flag
	  shipping_prefix
	  shipping_name
	  shipping_address1
	  shipping_address2
	  shipping_city
	  shipping_state
	  shipping_zip
	  shipping_comments
	  shipping_country
	  shipping_phone
	  shipping_fax
	  shipper
	  shipper_tracking_nbr
	  track1
	  track2
	  cnp_security
	  cnp_recurring
	);

	return @fields;
}

sub GetEchoProp {
	my( $self, $raw, $prop ) = @_;
	local $^W=0;

	my $data;
	($data) = $raw =~ m"<$prop>(.*?)</$prop>"gsi;
	$data =~ s/<.*?>/ /gs;
	chomp $data;
	return $data;
}

sub GetEchoReturn {
	my( $self, $page, $type ) = @_;
	local $^W=0;

	my $data;
	if ($type eq 'OPEN') {
		($data) = $page =~ m"<OPENECHO>(.*?)</OPENECHO>"gsi;
	}
	else {
		($data) = $page =~ m"<ECHOTYPE$type>(.*?)</ECHOTYPE$type>"gsi;
	}
#	$data =~ s"<.*?>" "g;
        #unless (length($data)) {
        #  warn "$self $page $type";
        #}

	chomp $data;
	return $data;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::OnlinePayment::SynapseGateway - SynapseGateway backend for Business::OnlinePayment

=head1 SYNOPSIS

use Business::OnlinePayment;

 my $tx = new Business::OnlinePayment("SynapseGateway");
  $tx->content(
      
      login				=> 'Demo-Syn',
      password			=> 'demo', #case sensitive
	  action			=> 'Normal Authorization', 
      amount			=> '1.00',
      invoice_number	=> '123456',
      customer_id		=> '123',
      description		=> 'Business::OnlinePayment test',
      card_number		=> '4111111111111111',
      name				=> 'Mr Customer',
      expiration		=> '12/12',
      address			=> '123 Main St',
      zip				=> '84058',
      cvv2				=> '123',  
  );

=head1 DESCRIPTION

Stub documentation for Business::OnlinePayment::SynapseGateway, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mike Dunham<lt>mdunham@synapsecorporation.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
