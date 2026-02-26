package Pod::Weaver::Section::SourceGitHub;

# ABSTRACT: Add SOURCE pod section for a github repository

use Moose;

with 'Pod::Weaver::Role::Section';

use Moose::Autobox;

has zilla => (
    is  => 'rw',
    isa => 'Dist::Zilla'
);

has repo_data => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $url = $self->zilla->distmeta->{resources}{repository}{url}
          or die "No repository URL found in distmeta";

        if ($url =~ /github\.com/i) {
            $url =~ s{^(?:https?|git):/*}{}i;
            $url =~ s{^git\@github.com:/*}{github.com/}i;
            $url =~ s/\.git$//i;

            return [ "https://$url.git", "https://$url" ];
        }

        return [];
    }
);

has repo_git => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->repo_data->[0] },
);

has repo_web => (
    is      => 'ro',
    lazy    => 1,
    default => sub { shift->repo_data->[1] },
);

=method weave_section

adds the C<SOURCE> section.

=cut

sub weave_section {
    my ($self, $document, $input) = @_;

    my $zilla = $input->{zilla} or return;
    $self->zilla($zilla);

    my $meta = eval { $zilla->distmeta }
        or die "no distmeta data present";

    # pull repo out of distmeta resources.
    my $repo = $meta->{resources}{repository}{url} or return;

    return unless $repo =~ /github\.com/i;

    my $repo_web = $self->repo_web;
    my $repo_git = $self->repo_git;

    my $text =
        "The development version is on github at L<$repo_web>\n".
        "and may be cloned from L<$repo_git>\n";

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

