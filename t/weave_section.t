#!perl

use strict;
use warnings;

use Test::More;
use Test::MockObject;

use Pod::Elemental::Document;
use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Weaver::Section::SourceGitHub;

sub make_weaver {
    my $weaver = Test::MockObject->new;
    $weaver->set_isa('Pod::Weaver');
    return $weaver;
}

sub make_section {
    Pod::Weaver::Section::SourceGitHub->new({
        plugin_name => 'SourceGitHub',
        weaver      => make_weaver(),
    });
}

sub make_zilla {
    my ($url) = @_;

    my $zilla = Test::MockObject->new;
    $zilla->set_isa('Dist::Zilla');
    $zilla->mock(distmeta => sub {
        { resources => { repository => { url => $url } } }
    });

    return $zilla;
}

sub make_document {
    Pod::Elemental::Document->new({ children => [] });
}

# Test: no zilla in input -> returns early, document unchanged
{
    my $section  = make_section();
    my $document = make_document();

    $section->weave_section($document, {});

    is scalar @{ $document->children }, 0,
        'no zilla in input: document unchanged';
}

# Test: non-GitHub repository URL -> returns early, document unchanged
{
    my $section  = make_section();
    my $document = make_document();
    my $zilla    = make_zilla('https://bitbucket.org/user/repo');

    $section->weave_section($document, { zilla => $zilla });

    is scalar @{ $document->children }, 0,
        'non-GitHub URL: document unchanged';
}

# Test: GitHub HTTPS URL with .git suffix
{
    my $section  = make_section();
    my $document = make_document();
    my $zilla    = make_zilla('https://github.com/user/repo.git');

    $section->weave_section($document, { zilla => $zilla });

    is scalar @{ $document->children }, 1,
        'HTTPS .git URL: one child added';

    my $head1 = $document->children->[0];
    is $head1->command, 'head1', 'HTTPS .git URL: command is head1';
    is $head1->content, 'SOURCE', 'HTTPS .git URL: content is SOURCE';

    my $text = $head1->children->[0]->content;
    like $text, qr{L<https://github\.com/user/repo>},
        'HTTPS .git URL: repo_web correct';
    like $text, qr{L<https://github\.com/user/repo\.git>},
        'HTTPS .git URL: repo_git correct';
}

# Test: GitHub git:// URL
{
    my $section  = make_section();
    my $document = make_document();
    my $zilla    = make_zilla('git://github.com/user/repo.git');

    $section->weave_section($document, { zilla => $zilla });

    is scalar @{ $document->children }, 1,
        'git:// URL: one child added';

    my $text = $document->children->[0]->children->[0]->content;
    like $text, qr{L<https://github\.com/user/repo>},
        'git:// URL: repo_web correct (scheme replaced)';
    like $text, qr{L<https://github\.com/user/repo\.git>},
        'git:// URL: repo_git correct (scheme replaced)';
}

# Test: GitHub SSH URL
{
    my $section  = make_section();
    my $document = make_document();
    my $zilla    = make_zilla('git@github.com:user/repo.git');

    $section->weave_section($document, { zilla => $zilla });

    is scalar @{ $document->children }, 1,
        'SSH URL: one child added';

    my $text = $document->children->[0]->children->[0]->content;
    like $text, qr{L<https://github\.com/user/repo>},
        'SSH URL: repo_web correct (normalized)';
    like $text, qr{L<https://github\.com/user/repo\.git>},
        'SSH URL: repo_git correct (normalized)';
}

# Test: GitHub HTTPS URL without .git suffix
{
    my $section  = make_section();
    my $document = make_document();
    my $zilla    = make_zilla('https://github.com/user/repo');

    $section->weave_section($document, { zilla => $zilla });

    is scalar @{ $document->children }, 1,
        'HTTPS no .git URL: one child added';

    my $text = $document->children->[0]->children->[0]->content;
    like $text, qr{L<https://github\.com/user/repo>},
        'HTTPS no .git URL: repo_web correct';
    like $text, qr{L<https://github\.com/user/repo\.git>},
        'HTTPS no .git URL: repo_git correct';
}

done_testing;
