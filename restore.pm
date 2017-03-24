package Restore;

use strict;
use warnings;

use YAML qw(LoadFile DumpFile);
use Data::Dumper;
use DBI;
use Term::UI;
use Term::ReadLine;


sub new{
        my $self;
        my $term = Term::ReadLine->new('brand');
        $self = {
                        term => $term,
                        db => 'backupdb',
                        tbl => 'idxtable',
                        dbh => '',
                        dir => '',
                        database_file => '',
                        };
        bless $self;
        return $self;
}

sub set_up_db{
        my $self = shift;
        my $dir = shift;
        if (!$dir){
                print "cannot find configuration file - you  have to use the '-y' parameter to givin location of configuration file\n";
                return;
        }
        my $database_file = $dir . '/' . $self->{db};
        my $create_table_sql = qq~ 'CREATE TABLE $self->{tbl} (
                                id int not null,
                                database char(250),
                                database_dir char(250),
                                host char(250),
                                bu_date char(10),
                                primary key (id))'~;

        if (! -e $database_file ){
                system( " sqlite3 -batch $database_file $create_table_sql ");
        }

        my $dbh = DBI->connect("dbi:SQLite:dbname=$database_file","","");
        $self->{dbh} = $dbh;
        $self->{dir} = $dir;
        $self->{database_file} = $database_file;
        $self->create_index_db;
        $self->process_index;
}

sub create_index_db{
        my $self = shift;
        my $dbdir = $self->{dbdir};
        my $dbh = $self->{dbh};
        my $sql = qq~select database from $self->{tbl} where id = 1~;
        my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
        $sth->execute() || die " could not do $sql - $self->{dbh}->errstr";
        my $found = $sth->fetchrow_hashref;
        $sth->finish( );
        unless ($found){
                $sql = "insert into $self->{tbl} (id,database,host,bu_date) values(1,'2','index_value','0000-00-00')";
                $sth = $dbh->prepare($sql) || die " error in $sql - $self->{dbh}->errstr";
                $sth->execute( ) || die " error in $sql - $self->{dbh}->errstr";
                $sth->finish( );
        }
}

sub process_index{
        my $self = shift;
        my $db = $self->{db};
        my $dir = $self->{dir};
        my $dbh = $self->{dbh};
        my $sth;
        if (! -e "$dir/index" ){
                my $sql = qq~delete from $self->{tbl} where id > 0~;
        $sth = $dbh->prepare($sql) ||  die " error in $sql  - $dbh->errstr";
                $sth->execute() || die " error in $sql  - $dbh->errstr";
                system(qq~ls ${dir}/* > ${dir}/index ~);
                $self->create_index_db();
        }
        my $fh;
    my @a;
        open $fh,"<","${dir}/index" or die "could not open ${dir}/index - $!";
        while ( my $line = <$fh> ){
                chomp $line;
                $line =~ s/:$//;
                if (! -d "$line"){
                        next;
                }
                @a = ();
                my $databases = $self->get_databases($line);
                my @v = split /\//,$line;
                my $nl = pop @v;
                my ($date) = ($nl =~ /^(\d+\-\d+\-\d+)-/);
                my ($tmp,$host) = ($nl =~ /^[\d\-\_]+(\S+)/);
                $a[0] = '';
                $a[1] = '';
                $a[2] = $line;
                $a[3] = $host;
                $a[4] = $date;
                for my $db (@{$databases}){
                        unless ( $self->exists_record($line,$db,$date) ){
                                my $index = $self->get_index();
                                $a[0] = $index;
                                $a[1] = $db;
                                my $insert_sql = qq~ insert into $self->{tbl} ( id,database,database_dir,host,bu_date)  values (?,?,?,?,?) ~;
                                $sth = $dbh->prepare($insert_sql) ||  die " could not do $insert_sql - $dbh->errstr";
                                $sth->execute(@a) || die " could not do $insert_sql - $dbh->errstr";
                        }
                }
        $sth->finish( );
        }
}

sub exists_record{
        my $self = shift;
        my $dir = shift;
        my $database = shift;
        my $bu_date = shift;
        my @a;
        push @a,$dir;
        push @a,$dir;
        push @a,$bu_date;
        my $sql = qq~select database from $self->{tbl} where database_dir = ? and database = ? and  bu_date = ? ~;
        my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
        $sth->execute(@a) || die " could not do $sql - $self->{dbh}->errstr";
        my $found = $sth->fetchrow_hashref;
    $sth->finish( );
        return ($found);
}


sub get_databases{
        my $self = shift;
        my $dir_line = shift;
        my @database_dir = ();
    opendir(my $dh, $dir_line) || die "can't opendir $dir_line ---  $!";
        while( my $line = readdir($dh) ){
                chomp $line;
                next if ($line =~ /^\./);
                push @database_dir, $line;
        }
    closedir $dh;
        return (\@database_dir);
}


sub get_index{
        my $self = shift;
        my $sql = qq~select database from $self->{tbl} where id = 1 ~;
    my $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
        $sth->execute() || die " could not do $sql - $self->{dbh}->errstr";
        my $hash  = $sth->fetchrow_hashref;
        my $return_id = $hash->{database};
        $hash->{database}++;
        $sql = qq~update $self->{tbl} set database = $hash->{database} where id = 1~;
    $sth = $self->{dbh}->prepare($sql) || die " could not do $sql - $self->{dbh}->errstr";
        $sth->execute() || die " could not do $sql - $self->{dbh}->errstr";
        return ($return_id);
}

sub process_restore{
        my $self = shift;
        my $reply = '';
        while (1){
                my $answer = $self->do_menu();
                if ($answer eq 'Exit'){
                        last;
                } elsif ( $answer eq 'Restore by Date/Database' ){
                        $reply = $self->select_restore_dates;
                } elsif ( $answer eq 'Show Databases' ){
                        $self->show_databases;
                }
        }
        return ($reply);
}

sub show_databases{
        my $self = shift;
        my @a;
        my $sql = qq~select database,bu_date from $self->{tbl} where id  <> 1 order by bu_date ~;
        my $sth = $self->{dbh}->prepare($sql) || die "error in $sql - $self->{dbh}->errstr";
        $sth->execute() || die " error on $sql - $self->{dbh}->errstr";
        print "Databases: \n";
        while ( my ($database,$date) =  $sth->fetchrow_array ){
                print "Database: $database Backup Date $date\n";
        }
    $sth->finish( );
        my $a = $self->{term}->ask_yn( prompt => 'Press enter to continue', default => 'y');
}


sub select_restore_dates{
        my $self = shift;
        my $hash;
        $hash->{database} = '';
        my $return_answer;
        while (1){
                unless ($hash->{database}){
                        $hash->{database} = $self->{term}->get_reply( prompt => 'Enter Database name (include the .sql)');
                }
                unless ($hash->{date}){
                        $hash->{date} = $self->{term}->get_reply( prompt => 'Enter Date (yyyy-mm-dd)');
                }
                if ($hash->{database} && $hash->{date}){
                        last;
                }
                my $return_answer = $self->{term}->ask_yn( prompt => 'Do you wish to exit this selection?', default => 'y');
                last if ($return_answer);
        }

        if ($return_answer){
                return 0;
        }
        my @a =();
        push @a, $hash->{date};
        push @a, $hash->{database};
        my @final_results = ();
        my $sql = qq~select database, bu_date from $self->{tbl} where bu_date = ? and database = ? ~;
        my $sth = $self->{dbh}->prepare($sql) || die "error in $sql - $self->{dbh}->errstr";
        $sth->execute(@a) || die " error on $sql - $self->{dbh}->errstr";
        while ( my @h =  $sth->fetchrow_array ){
                if (@h){
                        my $ln = join ',', @h;
                        push @final_results,$ln;
                }
        }
    $sth->finish( );
        if (!@final_results){
                push @final_results,'no records found for date ' . $hash->{date} . ' and database ' . $hash->{database};
        }
        push @final_results,'Exit';
        my $reply = $self->{term}->get_reply(
                prompt => 'Menu',
                choices => \@final_results,
                default => 'Exit',
        );
        return ($reply);
}

sub do_menu{
        my $self = shift;
        my $reply = $self->{term}->get_reply(
                prompt => 'Menu',
                choices => ["Restore by Date/Database","Show Databases","Exit"],
                default => 'Exit',
        );
}

1;
