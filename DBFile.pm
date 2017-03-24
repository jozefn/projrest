package DBFile;

use strict;
use warnings;
use Data::Dumper;
use DBI;

sub new{
        my $self;
        $self = {
                 db => './namddb',
                 tbl => 'name_table',
                 dbh => '',
                 database_file => '',
                };
        bless $self;
        return $self;
}

sub set_up_db{
        my $self = shift;
        my $database_file = $self->{db};
        my $create_table_sql = qq~ 'CREATE TABLE $self->{tbl} (
                                id int not null,
                                name char(250),
                                address char(250),
                                phone char(10),
                                primary key (id))'~;

        if (! -e $database_file ){
           system( " sqlite3 -batch $database_file $create_table_sql ");
        }

        my $dbh = DBI->connect("dbi:SQLite:dbname=$database_file","","");
        $self->{dbh} = $dbh;
        $self->{database_file} = $database_file;
        $self->create_index_db;
}

sub create_index_db{
	my $self = shift;
    my $dbh = $self->{dbh};
    my $sql = qq~select database from $self->{tbl} where id = 1~;
    my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
    $sth->execute() || die " could not do $sql - $self->{dbh}->errstr";
    my $found = $sth->fetchrow_hashref;
    $sth->finish( );
    unless ($found){
          $sql = "insert into $self->{tbl} (id,name,address,phone) values(1,'2','index_value','','')";
          $sth = $dbh->prepare($sql) || die " error in $sql - $self->{dbh}->errstr";
          $sth->execute( ) || die " error in $sql - $self->{dbh}->errstr";
          $sth->finish( );
    }
}

sub read_record_by_id{
    my $self = shift;
    my $id = shift;
	my @a;
	push @a, $id;
    my $sql = qq~select name from $self->{tbl} where id = ?  ~;
    my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
    $sth->execute(@a) || die " could not do $sql - $self->{dbh}->errstr";
    my $record = $sth->fetchrow_hashref;
    $sth->finish( );
    return ($record);
}

sub write_record{
    my $self = shift;
    my $hash = shift;
	my @a;
    my $sql = qq~update $self->{tbl} set ~; 
	foreach my $key ( sort keys %{$hash} ){
		next if ($key eq 'id');
		$sql .= qq~ $key = ?,~;
		push @a, $hash->{$key}
	}
	$sql .= qq~ where id = ?  ~;
	push @a, $hash->{id};
    my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
    $sth->execute(@a) || die " could not do $sql - $self->{dbh}->errstr";
    $sth->finish( );
}

sub list_records{
    my $self = shift;
    my $sql = qq~select * from $self->{tbl} where id != ?  ~;
    my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
    $sth->execute('1') || die " could not do $sql - $self->{dbh}->errstr";
	my @return_values;
	while ( my $record = $sth->fetchrow_hashref ){
		push @return_values, $record;
	}
    $sth->finish( );
    return (\@return_values);
}






1;
