
use strict;
use warnings;

use FileHandle;

use Pod::POM;
use Pod::POM::View::HTML;

use HTML::Template;

our $VERSION = '0.02';

my $FhIn = \*STDIN;
my $FhOut;

my $Text;

my $SlideFilename = shift; 
{
  if (defined $SlideFilename) {
    $FhIn = new FileHandle( $SlideFilename )
      or die "Unable to open file ``$SlideFilename\'\': $!";
  }

  while (my $line = <$FhIn>) {
    $Text .= $line;
  }

  if (defined $SlideFilename) {
    $FhIn->close;
  }
}

my $Parser = new Pod::POM();
my $Pom    = $Parser->parse_text( $Text )
  or die $Parser->error();

{
  my $toc_tmpl   = 'toc.template';
  my $slide_tmpl = 'slide.template';

  my $title    = undef;
  my @slides   = ( );
  my $index    = 1;

  my $gentime = localtime();

  my $toc_page  = "toc.html";
  my $prev_page = $toc_page;

  my $count     = @{$Pom->head1};

  my $tmpl_slide = new HTML::Template( filename => $slide_tmpl );


  foreach my $head1 ($Pom->head1()) {
    unless (defined $title) {
      $title = $head1->title();
    }

    my $filename  = sprintf('slide%03d.html', $index);
    my $next_page = sprintf('slide%03d.html', $index+1);

    push @slides, {
      page  => $filename,
      title => $head1->title(),
    };

    $tmpl_slide->param(
       main_title => $title,
       title => $head1->title(),
       body  => Pod::POM::View::HTML->print( $head1 ),
       time  => $gentime,
       toc   => $toc_page,
       prev  => $prev_page,
       next  => $next_page,
       count => $count,
       num   => $index,
       is_last => ($index == $count),
    );

    write_page( $filename, $tmpl_slide );

    $prev_page = $filename;

    $index++;
  }

  my $tmpl_toc = new HTML::Template( filename => $toc_tmpl );

  $tmpl_toc->param(
    title => $title,
    toc   => \@slides,
    time  => $gentime,
  );

  write_page( $toc_page, $tmpl_toc );

}

sub write_page {
  my $filename = shift;
  my $fh = new FileHandle( ">$filename" )
    or die "Unable to create file ``$filename\'\': $!";

  my $tmpl = shift;

  print STDERR $filename, "\n";

  print $fh $tmpl->output;

  $fh->close;
}


__END__

