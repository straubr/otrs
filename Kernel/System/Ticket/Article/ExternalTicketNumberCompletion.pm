package Kernel::System::Ticket::Article::ExternalTicketNumberCompletion;
use Kernel::System::VariableCheck qw(:all);

use strict;
use warnings;

sub ExternalTicketNumberCompletion {

    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(TicketID Subject)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # Exit if sender is not an agent
    if ($Param{SenderType}) {
        return $Param{Subject} if ($Param{SenderType} =~ /customer/ );
    }
    if ($Param{SenderTypeID}) {
        return $Param{Subject} if ($Param{SenderTypeID} == 3 );
    }

    # Exit if article type is not external
    if ($Param{ArticleType}) {
        return $Param{Subject} unless ($Param{ArticleType} =~ /ext/ );
    }
    if ($Param{ArticleTypeID}) {
        return $Param{Subject} unless ($Param{ArticleTypeID} == 1 || $Param{ArticleTypeID} == 3 );
    }

    # Exit if no external ticket number recognition is activated
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $RecognitionFilter = $ConfigObject->Get('PostMaster::PreFilterModule');
    
    # Remove the MatchDBSource from Hash - only interested in the recognition
    delete $RecognitionFilter->{'000-MatchDBSource'};
    return $Param{Subject} unless IsHashRefWithData($RecognitionFilter);

    # Get ticket and exit if no external ticket number were saved
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
        UserID        => 1,
    );

    RECOGNITIONFILTER:
    foreach my $Filter (keys $RecognitionFilter) {
        my $DynamicFieldName = "DynamicField_$RecognitionFilter->{$Filter}->{DynamicFieldName}";
        if (!$Ticket{$DynamicFieldName}) {
            next RECOGNITIONFILTER;
        }

        # Found a valid filter that actually saved a number to the ticket
        my $Orientation = $ConfigObject->Get('Ticket::ExternalTicketNumberCompletionFormat') || 0;
        # If number is not yet in the subject, add it.
        if ($Param{Subject} !~ m{ $RecognitionFilter->{$Filter}->{NumberRegExp} }msx ) {

             if ($Orientation eq 'Left') {
                 return $Ticket{$DynamicFieldName} . " " . $Param{Subject};
             } else {
                 return $Param{Subject} . " " . $Ticket{$DynamicFieldName};
             }
        }
    }
    return $Param{Subject};
}

1;
