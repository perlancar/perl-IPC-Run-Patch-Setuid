package IPC::Run::Patch::Setuid;

# DATE
# VERSION

use 5.010001;
use strict;
no warnings;
use Log::ger;

use Module::Patch ();
use base qw(Module::Patch);

our %config;

my $p_do_kid_and_exit = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    defined $config{-euid} or die "Please specify -euid";

    if (defined $config{-egid}) {
        log_trace "Setting EGID to $config{-egid} ...";
        if ($config{-egid} =~ /\A[0-9]+\z/) {
            # a single number, let's set groups to only this group
            my $groups = $); my $num_groups = 1; $num_groups++ while $groups =~ / /g;
            $) = join(" ", ($config{-egid}) x $num_groups);
        } else {
            $) = $config{-egid};
        }
    }

    log_trace "Setting EUID to $config{-euid} ...";
    $> = $config{-euid};

    $ctx->{orig}->(@_);
};

sub patch_data {
    return {
        v => 3,
        config => {
            -euid => {
                schema  => 'uint*',
                req => 1,
            },
            -egid => {
                summary => 'A GID or several GIDs separated by space',
                schema  => 'str*',
            },
        },
        patches => [
            {
                action => 'wrap',
                sub_name => '_do_kid_and_exit',
                code => $p_do_kid_and_exit,
            },
        ],
    };
}

1;
# ABSTRACT: Set EUID

=head1 SYNOPSIS

 use IPC::Run::Patch::Setuid -euid => 1000;


=head1 DESCRIPTION

This patch sets EUID of the child process (C<< $> >>) to the specified ID after
forking.


=head1 CONFIGURATION

=head2 -euid

Unsigned integer.


=head1 SEE ALSO

L<IPC::Run>

=cut
