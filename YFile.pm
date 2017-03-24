package YFile;

use strict;
use warnings;
use YAML qw(DumpFile LoadFile);
use Data::Dumper;

sub new{
        my $self;
        $self = {
                 yfile => './names.yaml',
                };
        bless $self;
		$self->create_yaml_index;
        return $self;
}

sub create_yaml_index{
	my $self = shift;
	my $hash = {};
    if (! -e $self->{yfile} ){
		$hash->{index} = 1;
		DumpFile($self->{yfile},$hash);
    }
}

sub write_new_record{
	my $self = shift;
	my $in_hash = shift;
	delete $in_hash->{id};
	my $fhash = LoadFile($self->{yfile});
	my $cnt = $fhash->{index};
	$fhash->{$cnt} = $in_hash;
	$cnt++;
	$fhash->{index} = $cnt;
	DumpFile($self->{yfile},$fhash);
}

	
	
sub read_all_records{
	my $self = shift;
	my $fhash = LoadFile($self->{yfile});
	my $return_hash = {};
	foreach my $key ( sort keys %{$fhash} ){
		next if ($key eq 'index');
		$return_hash->{$key} = $fhash->{$key};
	}
	if (! keys %{$return_hash}){
		$return_hash->{error} = 'there are no records in name.yaml';
	}
	return ($return_hash);
}

sub read_record_by_id{
	my $self = shift;
	my $id = shift;
	my $fhash = LoadFile($self->{yfile});
	my $return_hash = {};
	foreach my $key ( sort keys %{$fhash} ){
		next if ($key eq 'index');
		$return_hash->{$key} = $fhash->{$key};
	}
	if (! keys %{$return_hash}){
		$return_hash->{error} = 'there are no records in name.yaml';
	}
	return ($return_hash->{$id});
}



sub update_record{
	my $self = shift;
	my $in_hash = shift;
	my $action = shift;
	my $id = $in_hash->{id};
	my $fhash = LoadFile($self->{yfile});
	if ($action eq 'delete'){
		delete $fhash->{$id};
	} elsif ( $action eq 'update'){
		delete $in_hash->{$id};
		$fhash->{$id} = $in_hash;
	}
	DumpFile($self->{yfile},$fhash);
}

	
1;
