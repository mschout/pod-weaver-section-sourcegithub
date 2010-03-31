package Pod::Weaver::Section::SourceGitHub;

# ABSTRACT: Add SOURCE pod section for a github repository

use Moose;

with 'Pod::Weaver::Role::Section';

use Moose::Autobox;

=method weave_section

adds the C<SOURCE> section.

=cut

sub weave_section {
    my ($self, $document, $input) = @_;

    my $zilla = $input->{zilla} or return;

    my $meta = eval { $zilla->distmeta }
        or die "no distmeta data present";

    # pull repo out of distmeta resources.
    my $repo = $meta->{resources}{repository}
        or die "repository not present in distmeta";

    return unless $repo =~ /github\.com/;

    my $clonerepo = $repo;

    # fix up clone repo url
    if ($clonerepo =~ m#^http://#) {
        $clonerepo =~ s#^http://#git://#;
    }
    if ($clonerepo !~ /\.git$/) {
        $clonerepo .= '.git';
    }

    my $text =
        "You can contribute or fork this project via github:\n".
        "\n".
        "$repo\n";

    # if repo differs from the clone repo, add clone command.
    if ($clonerepo ne $repo) {
        $text .= "\n".
                 " git clone $clonerepo";
    }

    $document->children->push(
        Pod::Elemental::Element::Nested->new({
            command => 'head1',
            content => 'SOURCE',
            children => [
                Pod::Elemental::Element::Pod5::Ordinary->new({content => $text}),
            ],
        }),
    );
}

no Moose;
1;

__END__

=head1 SYNOPSIS

in C<weaver.ini>:

 [SourceGitHub]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that gives the github URL for
your module, as well as instructions on how to clone the repository.

