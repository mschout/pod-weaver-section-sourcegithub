package Pod::Weaver::Section::SourceGitHub;
$Pod::Weaver::Section::SourceGitHub::VERSION = '0.57';
# ABSTRACT: Add SOURCE pod section for a github repository

use Moose;

with 'Pod::Weaver::Role::Section';

use Moose::Autobox;

has zilla => (
    is  => 'rw',
    isa => 'Dist::Zilla');

has repo_data => (
    is         => 'ro',
    lazy_build => 1);

has repo_git => (
    is         => 'ro',
    lazy_build => 1);

has repo_web => (
    is         => 'ro',
    lazy_build => 1);


sub weave_section {
    my ($self, $document, $input) = @_;

    my $zilla = $input->{zilla} or return;
    $self->zilla($zilla);

    my $meta = eval { $zilla->distmeta }
        or die "no distmeta data present";

    # pull repo out of distmeta resources.
    my $repo = $meta->{resources}{repository}{url} or return;

    return unless $repo =~ /github\.com/;

    my $clonerepo = $repo;

    # fix up clone repo url
    my $repo_web = $self->repo_web;
    my $repo_git = $self->repo_git;

    my $text =
        "The development version is on github at L<".$self->repo_web.">\n".
        "and may be cloned from L<".$self->repo_git.">\n";

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

sub _build_repo_data {
    my $self = shift;

    my $url = $self->zilla->distmeta->{resources}{repository}{url}
        or die "No repository URL found in distmeta";

    if ($url =~ /github\.com/i) {
        $url =~ s{^(?:http|git):/*}{}i;
        $url =~ s{^git\@github.com:/*}{github.com/}i;
        $url =~ s/\.git$//i;

        return [ "$url.git", $url ];
    }

    return [];
}

sub _build_repo_git {
    shift->repo_data->[0];
}

sub _build_repo_web {
    shift->repo_data->[1];
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::SourceGitHub - Add SOURCE pod section for a github repository

=head1 VERSION

version 0.57

=head1 SYNOPSIS

in C<weaver.ini>:

 [SourceGitHub]

=head1 OVERVIEW

This section plugin will produce a hunk of Pod that gives the github URL for
your module, as well as instructions on how to clone the repository.

=head1 METHODS

=head2 weave_section

adds the C<SOURCE> section.

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/pod-weaver-section-sourcegithub>
and may be cloned from L<https://github.com/mschout/pod-weaver-section-sourcegithub.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/pod-weaver-section-sourcegithub/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
