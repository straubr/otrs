# --
# Kernel/System/PostMaster/LoopProtection.pm - sub part of PostMaster.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: LoopProtection.pm,v 1.18 2012-11-12 18:07:30 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.
# --

package Kernel::System::PostMaster::LoopProtection;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.18 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed  objects
    for (qw(DBObject LogObject ConfigObject MainObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    # load backend module
    my $BackendModule = $Self->{ConfigObject}->Get('LoopProtectionModule')
        || 'Kernel::System::PostMaster::LoopProtection::DB';
    if ( !$Self->{MainObject}->Require($BackendModule) ) {
        $Self->{MainObject}->Die("Can't load loop protection backend module $BackendModule! $@");
    }

    $Self->{Backend} = $BackendModule->new(%Param);

    return $Self;
}

sub SendEmail {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->SendEmail(%Param);
}

sub Check {
    my ( $Self, %Param ) = @_;

    return $Self->{Backend}->Check(%Param);
}

1;
