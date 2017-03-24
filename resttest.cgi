#!"C:\xampp\perl\bin\perl.exe"

use strict;
use lib qw(./);
use YFile;
use CGI;
use Data::Dumper;
use JSON;

my $yfile = new YFile;

my $cgi = new CGI;
print $cgi->header('application/json');

my $json_hash;
my $action = $ENV{'REQUEST_METHOD'};
my $path_info = $ENV{'PATH_INFO'};
$path_info =~ s/\///;

if ( $action eq 'GET' ){
	my $id = $cgi->param('id');
	if ($id){
		($json_hash) = $yfile->read_record_by_id($id);
	} else {
		($json_hash) = $yfile->read_all_records;
	}
	
} elsif ( $action eq 'POST' ){
	my $hash = get_client_data();
	$yfile->write_new_record($hash);
	$json_hash->{message} = "$hash->{name} was added to the file";
} elsif ( $action eq 'PUT' ){
	my ($hash) = get_client_data();
	$yfile->update_record($hash,'update');
	$json_hash->{message} = "$hash->{name} has been updated";
} elsif ( $action eq 'DELETE' ){
	my $delete_hash;
	($json_hash) = $yfile->read_record_by_id($path_info);
	$delete_hash->{id} = $path_info;
	$yfile->update_record($delete_hash,'delete');
	$json_hash->{message} = "$json_hash->{name} has been deleted";
}

my $json_text   = to_json( $json_hash, { ascii => 1, pretty => 1 } );
print $json_text;


sub get_client_data{
	my $hash ={};
    my $id = $cgi->param('id');	
    my $name = $cgi->param('name');	
    my $address = $cgi->param('address');	
    my $phone = $cgi->param('phone');	
	$hash->{name} = $name;
	$hash->{address} = $address;
	$hash->{phone} = $phone;
	$hash->{id} = $id;
	return ($hash);
}

