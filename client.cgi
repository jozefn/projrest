#!"C:\xampp\perl\bin\perl.exe"

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Term::UI;
use Term::ReadLine;
use JSON;
my $ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");
my $url = 'http://localhost/cgi-bin/project/resttest.cgi';
my $term = Term::ReadLine->new('client');
process_menu();

exit(0);

sub process_menu{
    my $reply = '';
    while (1){
    	my $answer = do_menu();
        if ($answer eq 'Exit'){
            last;
        } elsif ( $answer eq 'Display All' ){
          	$reply = select_records(1);
        } elsif ( $answer eq 'New Record' ){
		    create_new_record();
        } elsif ( $answer eq 'Update Record' ){
			update_record();
        } elsif ( $answer eq 'Delete Record' ){
			delete_record();
        }
	}
}

sub update_record{
   	my $reply = select_records();
	if ($reply =~ /^Exit/){
		return;
	}
	my ($key) = ($reply =~ /^(\d+)\s/);
	my $req = HTTP::Request->new('GET', $url);
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("id=$key");
	my $res = return_action($req);
   	my $select_hash = from_json($res->content);
	my $pass_hash = $select_hash->{$key};
	my ($nrec) = get_record_info($pass_hash);
	$req = HTTP::Request->new('PUT', $url);
	$req->content_type('application/x-www-form-urlencoded');
	my $query = "id=$key&";
	foreach my $k ( keys %{$nrec} ){
		$query .= "$k=$nrec->{$k}&";
	}
	$query =~ s/&$//;
	$req->content($query);
	$res = return_action($req);
   	my $m = from_json($res->content);
	print "$m->{message}\n";

}

sub delete_record{
   	my $reply = select_records();
	if ($reply =~ /^Exit/){
		return;
	}
	my ($key) = ($reply =~ /^(\d+)\s/);
	$url .= "/$key";
	my $req = HTTP::Request->new('DELETE', $url);
	$req->content_type('application/x-www-form-urlencoded');
	my $res = return_action($req);
   	my $m = from_json($res->content);
	print "$m->{message}\n";
}



sub select_records{
	my $return_flag = shift || 0;
	my $req = HTTP::Request->new('GET', $url);
	$req->content_type('application/x-www-form-urlencoded');
	my $res = return_action($req);
   	my $select_hash = from_json($res->content);
	my @final_results = ();
	if (exists $select_hash->{error} ){
         push @final_results,$select_hash->{error};
    } else {
		foreach my $key ( sort keys %{$select_hash} ){
			push @final_results, "$key - $select_hash->{$key}->{name} - $select_hash->{$key}->{address} - $select_hash->{$key}->{phone} ";
		}
	}
	my $reply;
	if ($return_flag){
		my $cnt = 1;
		print "\t\n Contents of file \n";
		for my $value (@final_results){
			print "\t$cnt> $value\n";
		}
		return;
	} else {
    	push @final_results,'Exit Sub-menu';
    	$reply = $term->get_reply(
                prompt => 'Menu',
                choices => \@final_results,
                default => 'Exit Sub-menu',
        );
    	return ($reply);
	}
}




sub create_new_record{
	my ($nrec) = get_record_info();
	my $req = HTTP::Request->new('POST', $url);
	$req->content_type('application/x-www-form-urlencoded');
	my $query;
	foreach my $key ( keys %{$nrec} ){
		$query .= $key . "=" . $nrec->{$key} . '&';
	}
	$query =~ s/&$//;
	$req->content($query);
	my $res = return_action($req);
   	my $m = from_json($res->content);
	print "$m->{message}\n";
}

sub get_record_info{
	my $nrec = shift || {};
	my ($name,$address,$phone);
	if ( keys %{$nrec} ){
		$name = $nrec->{name};
		$address = $nrec->{address};
		$phone = $nrec->{phone};
		print "Current value: $name - press enter to keep this value\n";
    	$nrec->{name} = $term->get_reply( prompt => 'Enter Name', default=>$name);
		print "Current value: $address - press enter to keep this value\n";
    	$nrec->{address} = $term->get_reply( prompt => 'Enter Address',default=>$address);
		print "Current value: $phone - press enter to keep this value\n";
    	$nrec->{phone} = $term->get_reply( prompt => 'Enter Phone',default=>$phone);
	} else {
    	$nrec->{name} = $term->get_reply( prompt => 'Enter Name');
    	$nrec->{address} = $term->get_reply( prompt => 'Enter Address');
    	$nrec->{phone} = $term->get_reply( prompt => 'Enter Phone');
	}
	return ($nrec);
}

sub return_action{
	my $req = shift;
	my $res = $ua->request($req);
	if ($res->is_success) {
		return ($res);
	} else {
    	die $res->status_line, "\n";
	}
}


sub do_menu{
    my $reply = $term->get_reply(
       prompt => 'Menu',
       choices => ["Display All","New Record","Update Record", "Delete Record" ,"Exit"],
       default => 'Exit',
    );
	return ($reply);
}


