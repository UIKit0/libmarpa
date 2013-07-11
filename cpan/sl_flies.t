#!perl
# Copyright 2012 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Demo of abstract syntax forest -- An Ada Lovelace quote

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use GetOpt::Long;

use Marpa::R2;

sub usage {

    die <<"END_OF_USAGE_MESSAGE";
    $PROGRAM_NAME
    $PROGRAM_NAME --stdin < file
With --stdin arg, reads expression from standard input.
By default, runs a test.
END_OF_USAGE_MESSAGE
} ## end sub usage

my $stdin_flag = 0;
my $getopt_result = Getopt::Long::GetOptions( 'stdin!' => \$stdin_flag, );
usage() if not $getopt_result;

my $input;
if ($stdin_flag) {
    $input = do { local $INPUT_RECORD_SEPARATOR = undef; <> };
}

my $rules = <<'END_OF_GRAMMAR';
:default ::= action => ::array bless => ::lhs
lexeme default = action => [value] bless => ::name
:start ::= <my start>
<my start> ::= root
root ::= S period trailer
ADJP ::= JJ CC JJ
ADJP ::= RB JJR
ADVP ::= ADVP CC ADVP
ADVP ::= ADVP PP
ADVP ::= ADVP comma ADVP
ADVP ::= RB
ADVP ::= RBS
CONJP ::= CC RB
CONJP ::= RB RB IN
NP ::= <PRP S> NN
NP ::= <PRP S> NN POS NNS
NP ::= ADJP NNS
NP ::= DT
NP ::= DT ADJP NN
NP ::= DT JJ CC JJ NNS
NP ::= DT JJ NN
NP ::= DT JJ NNS
NP ::= DT NN
NP ::= DT NNS
NP ::= DT VBG NNS
NP ::= JJ NN
NP ::= JJ JJ NNS
NP ::= NN
NP ::= NN comma NN CC JJ NNS
NP ::= NP PP
NP ::= NP SBAR
NP ::= NP colon NP comma bless => cherry1
NP ::= NP comma CC NP
NP ::= NP comma CONJP NP
NP ::= NP comma SBAR
NP ::= NP comma SBAR comma
NP ::= PRP
NP ::= <PRP S> NNS
PP ::= ADVP IN NP
PP ::= IN IN NP
PP ::= IN NP
PP ::= TO <PRP S> JJ JJ NNS
PP ::= TO NP
S ::= ADVP NP VP
S ::= ADVP VP
S ::= NP VP
S ::= S CONJP S
S ::= VP
SBAR ::= IN S
SBAR ::= S
SBAR ::= WHADVP S
SBAR ::= WHNP S
SBAR ::= WHNP comma ADVP comma S
SBAR ::= WHPP S
VP ::= ADVP VB NP
VP ::= TO VP
VP ::= MD ADVP VP
VP ::= MD VP
VP ::= VB NP
VP ::= VB S
VP ::= VB PP NP
VP ::= VBG NP
VP ::= VBG PP
VP ::= VBN PP PP
VP ::= VBN SBAR
VP ::= VBP ADVP VP
VP ::= VBP NP
VP ::= VBP NP PP
VP ::= VBP PP PP
VP ::= VBZ NP
VP ::= VBZ VP
WHADVP ::= WRB
WHNP ::= <WP S> NNS
WHNP ::= WDT
WHNP ::= WP
WHPP ::= IN WHNP

trailer ::= lexeme*
lexeme ::= CC | DT | IN | JJ | JJR | MD | NN | NNS |
    POS | PRP | <PRP S> | RB | RBS | TO |
    VB | VBG | VBN | VBP | VBZ |
    WDT | WP | <WP S> | WRB

lexeme ::= comma
lexeme ::= colon
lexeme ::= period

CC ~ never
DT ~ never
IN ~ never
JJ ~ never
JJR ~ never
MD ~ never
NN ~ never
NNS ~ never
POS ~ never
PRP ~ never
<PRP S> ~ never
RB ~ never
RBS ~ never
TO ~ never
VB ~ never
VBG ~ never
VBN ~ never
VBP ~ never
VBZ ~ never
WDT ~ never
WP ~ never
<WP S> ~ never
WRB ~ never

never ~ [^\d\D]
comma ~ ','
colon ~ ':'
period ~ '.'
END_OF_GRAMMAR

my $slg = Marpa::R2::Scanless::G->new(
    {   action_object  => 'My_Nodes',
        bless_package => 'My_Nodes',
        source         => \$rules,
    }
);
my $g1_grammar = $slg->thick_g1_grammar();

my $quotation = <<'END_OF_QUOTATION';
Those who view mathematical science,
not merely as a vast body of abstract and immutable truths,
whose intrinsic beauty,
symmetry and logical completeness,
when regarded in their connexion together as a whole,
entitle them to a prominent place in the interest of all profound
and logical minds,
but as possessing a yet deeper interest for the human race,
when it is remembered that this science constitutes the language
through which alone we can adequately express the great facts of
the natural world,
and those unceasing changes of mutual relationship which,
visibly or invisibly,
consciously or unconsciously to our immediate physical perceptions,
are interminably going on in the agencies of the creation we live amidst:
those who thus think on mathematical truth as the instrument through
which the weak mind of man can most effectually read his Creator's
works,
will regard with especial interest all that can tend to facilitate
the translation of its principles into explicit practical forms.
END_OF_QUOTATION

my $slr = Marpa::R2::Scanless::R->new( { grammar => $slg,
        ranking_method => 'high_rule_only' } );

my %punctuation = ( q{,} => 'comma', q{:} => 'colon', q{.} => 'period' );
my $lexeme_data = setup_lexemes();
# die Data::Dumper::Dumper($lexeme_data);
my $quote_length = length $quotation;
$slr->read(\$quotation, 0, 0);
LEXEME: while ( 1 ) {

    # Space forward
    $quotation =~ m/ \G ( [\s]* ) /gxms;
    my $start = pos $quotation;
    last LEXEME if $start >= $quote_length ;
    my ($match) = ($quotation =~ m/ \G ( [']? [[:alnum:]]+ ) /gxmsc);
    if ( defined $match ) {
        my $lexemes = $lexeme_data->{ lc $match };
        die qq{Unknown lexeme "$match"} if not defined $lexemes;
        for my $lexeme ( @{$lexemes} ) {
            $slr->lexeme_alternative($lexeme, $match);
            # say STDERR qq{Found "$match" as "$lexeme" at }, pos $quotation;
        }
        $slr->lexeme_complete($start, length $match);
        pos $quotation = $start + length $match;
        next LEXEME;
    } ## end if ( defined $match )
    my $next_char = substr $quotation, ( pos $quotation ), 1 ;
    my $punctuation = $punctuation{ $next_char };
    die qq{Unknown char ("$next_char") at pos }, (pos $quotation), " in quote"
        if not  defined $punctuation ;
    $slr->lexeme_alternative($punctuation, $next_char);
    $slr->lexeme_complete($start, 1);
    # say STDERR qq{Found "$punctuation" at $start};
    pos $quotation = (pos $quotation) + 1;
} ## end LEXEME: while ( pos $quotation < $quote_length )

my $asf = Marpa::R2::Scanless::ASF->new(
    {   slr     => $slr,
        choice  => 'My_ASF::choix',
        default => 'My_ASF'
    }
);

my $ambiguities = $asf->ambiguities();
say "Ambiguities: ", join " ", @{$ambiguities};

my %desc_to_cp_list = ();
explore_cp( $asf );

# Description is key, value is dump level
my %choices_to_dump = (
     '157.15' => 999,
);
for my $desc ( keys %choices_to_dump )
{
    my $dump_level = $choices_to_dump{$desc};
    my $cp_list    = $desc_to_cp_list{$desc};
    die "No CP list for desc $desc" if not defined $cp_list;
    for my $cp ( @{$cp_list} ) {
        my $tree = penn_str( $asf, $cp, $dump_level );
        say
            "Dump of $desc, choicepoint $cp to level $dump_level\n",
            Data::Dumper::Dumper($tree);
    } ## end for my $cp ( @{$cp_list} )
}

sub dump_cp {
    my ( $asf, $cp, $depth ) = @_;
    if ( defined( my $symbol = $asf->cp_token_name($cp) ) ) {
        return [ $symbol, $asf->cp_literal($cp) ];
    }
    my $brief_rule = $asf->cp_brief($cp);
    if ( $depth <= 0 ) {
        return [ $brief_rule, $asf->cp_literal($cp) ];
    }
    my $choices = $asf->choices($cp);
    my @return_value = ( ( scalar @{$choices} . ' Choices' ) );
    for my $choice ( @{$choices} ) {
        push @return_value,
            [
            $brief_rule,
            [ map { dump_cp( $asf, $_, $depth - 1 ) } @{$choice} ]
            ];
    } ## end for my $choice ( @{$choices} )
    return \@return_value;
} ## end sub dump_cp

sub penn_cp {
    my ( $asf, $cp, $depth ) = @_;
    if (defined (my $symbol = $asf->cp_token_name($cp))) {
        return [ $symbol, $asf->cp_literal( $cp ) ];
    }
    my ($lhs) = $asf->cp_rule($cp);
    if ($depth <= 0) {
        return [ $lhs, $asf->cp_literal( $cp ) ];
    }
    my $choices = $asf->choices( $cp );
    my @return_value = ( 'Choices: ' . (scalar @{$choices} ) );
    for my $choice (@{$choices}) {
        push @return_value, [ $lhs, [ map { penn_cp( $asf, $_, $depth - 1) } @{$choice} ] ];
    }
    return \@return_value;
}

sub penn_str {
    my ( $asf, $cp, $depth ) = @_;
    if ( defined( my $symbol = $asf->cp_token_name($cp) ) ) {
        return [ "($symbol " . $asf->cp_literal($cp) . ')' ];
    }
    my ($lhs) = $asf->cp_rule($cp);
    if ( $depth <= 0 ) {
        return [ "($lhs " . $asf->cp_literal($cp) . ')' ];
    }
    my $choices      = $asf->choices($cp);
    my @return_value = ();
    for my $choice ( @{$choices} ) {
        my @choices_so_far = ('');
        for my $child_cp ( @{$choice} ) {
            my @left_choices = @choices_so_far;
            @choices_so_far = ();
            my $right_choices = penn_str( $asf, $child_cp, $depth - 1 );
            for my $left_choice (@left_choices) {
                for my $right_choice (@{$right_choices}) {
                    push @choices_so_far, join q{ }, $left_choice,
                        $right_choice;
                }
            } ## end for my $left_choice (@current_choices)
        } ## end for my $child_cp ( @{$choice} )
        push @return_value, map { "($lhs " . $_ . ')' } @choices_so_far;
    } ## end for my $choice ( @{$choices} )
    return \@return_value;
} ## end sub penn_str

sub cp_to_desc {
    my ( $asf, $cp ) = @_;
    my $desc = join q{.}, $asf->cp_span($cp);
    push @{$desc_to_cp_list{$desc}}, $cp;
    return $desc;
}

sub pick_choice {
    state $cherry_picks = {
     '0.172' => 'My_Nodes::cherry1',
    };
    my ( $asf, $rcp ) = @_;
    my $desc = cp_to_desc($asf, $rcp);
    my $cherry_pick = $cherry_picks->{$desc};
    return undef if not defined $cherry_pick;
    my $choices = $asf->choices( $rcp );
    return 0 if scalar @{$choices} == 1;
    for my $choice_ix ( 0 .. $#{$choices} ) {
        my $choice = $choices->[$choice_ix];
        return $choice_ix if  grep { $asf->cp_blessing($_) eq $cherry_pick } @{$choice};
    }
    return undef;
}

sub explore_cp {
    my ( $asf, $cp, $data ) = @_;
    $cp //= $asf->top_choicepoint();
    return if $asf->cp_is_token( $cp );    # Do nothing if token

    $data //= { seen => [] };
    my $seen = $data->{seen};
    return if $seen->[$cp];
    $seen->[$cp] = 1;

    my $choices = $asf->choices($cp);
    my $pick = scalar @{$choices} <= 1 ? 0 : pick_choice( $asf, $cp );
    if ( defined $pick ) {
        my $choice = $choices->[$pick];
        explore_cp( $asf, $_, $data ) for @{$choice};
        return;
    }
    my $recurse_mask = show_ambiguity( $asf, $cp );
    if ( defined $recurse_mask ) {
        for my $choice ( @{$choices} ) {
            CHOICE: for my $choice_ix ( 0 .. $#{$choice} ) {
                if ( $recurse_mask->[$choice_ix] ) {
                    explore_cp( $asf, $_->[$choice_ix], $data )
                        for @{$choices};
                    next CHOICE;
                }
            } ## end CHOICE: for my $choice_ix ( 0 .. $#{$choice} )
        } ## end for my $choice ( @{$choices} )
    } ## end if ( defined $recurse_mask )
    return;

} ## end sub explore_cp

sub show_ambiguity_instance {
    my ( $asf, $child ) = @_;
    if ( defined( my $token_name = $asf->cp_token_name($child) ) ) {
        say "  === TOKEN $token_name ===";
        return;
    }
    say "  === RULE: ", $asf->cp_brief($child);
    return;
} ## end sub show_ambiguity_instance

sub show_ambiguity {
    my ( $asf, $choicepoint_id ) = @_;
    my @recurse_mask = ();
    my $choices = $asf->choices( $choicepoint_id );
    if ( !$asf->is_factored($choicepoint_id) ) {
        my $choices_by_rhs = $asf->choices_by_rhs($choicepoint_id);
        CHOICE: for my $rhs_ix ( 0 .. $#{$choices_by_rhs} ) {
            my $choices_at_rhs_ix = $choices_by_rhs->[$rhs_ix];
            if ( $#{$choices_at_rhs_ix} <= 0 ) {
                push @recurse_mask, 1;
                next CHOICE;
            }
            push @recurse_mask, 0;
            my $first_choice = $choices_at_rhs_ix->[0];
            my $desc = cp_to_desc($asf, $first_choice);
            say "=== $desc ", ( scalar @{$choices} ),
                " SYMBOLIC CHOICES for this text ===";
            say $asf->cp_literal($first_choice);
            say "=== END OF TEXT ===";
            show_ambiguity_instance( $asf, $_ ) for @{$choices_at_rhs_ix};
            say "=== $desc END OF SYMBOLIC CHOICES ===";
        } ## end CHOICE: for my $rhs_ix ( 0 .. $#{$choices_by_rhs} )
        return \@recurse_mask;
    } ## end if ( !$asf->is_factored($choicepoint_id) )
    say "=== ", (scalar @{$choices}), " factorings for this text ===";
    say $asf->choicepoint_literal($choicepoint_id),
    say "=== END OF TEXT ===";
    my $desc = cp_to_desc($asf, $choicepoint_id);
    for my $choice_ix (0 .. $#{$choices}) {
        my $choice = $choices->[$choice_ix] ;
        say "=== $desc FACTORING $choice_ix ===";
        CHILD: for my $child_ix (0 .. $#{$choice}) {
            my $child = $choice->[$child_ix];
            if ( defined( my $token_name = $asf->cp_token_name($child) ) ) {
                say "  === TOKEN CHILD: $token_name ===";
                next CHILD;
            }
            say "  === CHILD $child_ix, Rule ", $asf->cp_brief($child), " ===";
            say $asf->choicepoint_literal($child),
        }
    }
    say "=== $desc END OF FACTORINGS ===";
    return;
}

sub setup_lexemes {
    my %lexeme_data = ();
    push @{ $lexeme_data{"'s"} },            'POS';
    push @{ $lexeme_data{'creator'} },       'NN';
    push @{ $lexeme_data{'a'} },             'DT';
    push @{ $lexeme_data{'abstract'} },      'JJ';
    push @{ $lexeme_data{'adequately'} },    'RB';
    push @{ $lexeme_data{'agencies'} },      'NNS';
    push @{ $lexeme_data{'all'} },           'DT';
    push @{ $lexeme_data{'alone'} },         'RB';
    push @{ $lexeme_data{'amidst'} },        'NN';
    push @{ $lexeme_data{'and'} },           'CC';
    push @{ $lexeme_data{'are'} },           'VBP';
    push @{ $lexeme_data{'as'} },            'IN';
    push @{ $lexeme_data{'as'} },            'RB';
    push @{ $lexeme_data{'beauty'} },        'NN';
    push @{ $lexeme_data{'body'} },          'NN';
    push @{ $lexeme_data{'but'} },           'CC';
    push @{ $lexeme_data{'can'} },           'MD';
    push @{ $lexeme_data{'changes'} },       'NNS';
    push @{ $lexeme_data{'completeness'} },  'NNS';
    push @{ $lexeme_data{'connexion'} },     'NN';
    push @{ $lexeme_data{'consciously'} },   'RB';
    push @{ $lexeme_data{'constitutes'} },   'VBZ';
    push @{ $lexeme_data{'creation'} },      'NN';
    push @{ $lexeme_data{'deeper'} },        'JJR';
    push @{ $lexeme_data{'do'} },            'VBP';
    push @{ $lexeme_data{'effectually'} },   'RB';
    push @{ $lexeme_data{'entitle'} },       'VBP';
    push @{ $lexeme_data{'especial'} },      'JJ';
    push @{ $lexeme_data{'explicit'} },      'JJ';
    push @{ $lexeme_data{'express'} },       'VB';
    push @{ $lexeme_data{'facilitate'} },    'VB';
    push @{ $lexeme_data{'facts'} },         'NNS';
    push @{ $lexeme_data{'first'} },         'JJ';
    push @{ $lexeme_data{'for'} },           'IN';
    push @{ $lexeme_data{'forms'} },         'NNS';
    push @{ $lexeme_data{'going'} },         'VBG';
    push @{ $lexeme_data{'great'} },         'JJ';
    push @{ $lexeme_data{'his'} },           'PRP S';
    push @{ $lexeme_data{'human'} },         'JJ';
    push @{ $lexeme_data{'immediate'} },     'JJ';
    push @{ $lexeme_data{'immutable'} },     'JJ';
    push @{ $lexeme_data{'in'} },            'IN';
    push @{ $lexeme_data{'instrument'} },    'NN';
    push @{ $lexeme_data{'interest'} },      'NN';
    push @{ $lexeme_data{'interminably'} },  'RB';
    push @{ $lexeme_data{'into'} },          'IN';
    push @{ $lexeme_data{'intrinsic'} },     'NNS';
    push @{ $lexeme_data{'invisibly'} },     'RB';
    push @{ $lexeme_data{'is'} },            'VBZ';
    push @{ $lexeme_data{'it'} },            'PRP';
    push @{ $lexeme_data{'its'} },           'PRP S';
    push @{ $lexeme_data{'language'} },      'NN';
    push @{ $lexeme_data{'live'} },          'VBP';
    push @{ $lexeme_data{'logical'} },       'JJ';
    push @{ $lexeme_data{'man'} },           'NN';
    push @{ $lexeme_data{'math'} },          'NN';
    push @{ $lexeme_data{'mathematical'} },  'JJ';
    push @{ $lexeme_data{'merely'} },        'RB';
    push @{ $lexeme_data{'mind'} },          'NN';
    push @{ $lexeme_data{'minds'} },         'NNS';
    push @{ $lexeme_data{'most'} },          'RBS';
    push @{ $lexeme_data{'mutual'} },        'JJ';
    push @{ $lexeme_data{'natural'} },       'JJ';
    push @{ $lexeme_data{'not'} },           'RB';
    push @{ $lexeme_data{'of'} },            'IN';
    push @{ $lexeme_data{'on'} },            'IN';
    push @{ $lexeme_data{'or'} },            'CC';
    push @{ $lexeme_data{'other'} },         'JJ';
    push @{ $lexeme_data{'our'} },           'PRP S';
    push @{ $lexeme_data{'perceptions'} },   'NNS';
    push @{ $lexeme_data{'physical'} },      'JJ';
    push @{ $lexeme_data{'place'} },         'NN';
    push @{ $lexeme_data{'possessing'} },    'VBG';
    push @{ $lexeme_data{'practical'} },     'JJ';
    push @{ $lexeme_data{'principles'} },    'NNS';
    push @{ $lexeme_data{'profound'} },      'JJ';
    push @{ $lexeme_data{'prominent'} },     'JJ';
    push @{ $lexeme_data{'race'} },          'NN';
    push @{ $lexeme_data{'read'} },          'VB';
    push @{ $lexeme_data{'regard'} },        'VB';
    push @{ $lexeme_data{'regarded'} },      'VBN';
    push @{ $lexeme_data{'relationship'} },  'NN';
    push @{ $lexeme_data{'remembered'} },    'VBN';
    push @{ $lexeme_data{'science'} },       'NN';
    push @{ $lexeme_data{'something'} },     'NN';
    push @{ $lexeme_data{'symmetry'} },      'NN';
    push @{ $lexeme_data{'tend'} },          'VB';
    push @{ $lexeme_data{'that'} },          'DT';
    push @{ $lexeme_data{'that'} },          'IN';
    push @{ $lexeme_data{'that'} },          'WDT';
    push @{ $lexeme_data{'the'} },           'DT';
    push @{ $lexeme_data{'their'} },         'PRP S';
    push @{ $lexeme_data{'them'} },          'PRP';
    push @{ $lexeme_data{'thing'} },         'NN';
    push @{ $lexeme_data{'things'} },        'NNS';
    push @{ $lexeme_data{'think'} },         'VBP';
    push @{ $lexeme_data{'this'} },          'DT';
    push @{ $lexeme_data{'those'} },         'DT';
    push @{ $lexeme_data{'through'} },       'IN';
    push @{ $lexeme_data{'thus'} },          'RB';
    push @{ $lexeme_data{'to'} },            'TO';
    push @{ $lexeme_data{'together'} },      'RB';
    push @{ $lexeme_data{'translation'} },   'NN';
    push @{ $lexeme_data{'truth'} },         'NN';
    push @{ $lexeme_data{'truths'} },        'NNS';
    push @{ $lexeme_data{'unceasing'} },     'VBG';
    push @{ $lexeme_data{'unconsciously'} }, 'RB';
    push @{ $lexeme_data{'vast'} },          'JJ';
    push @{ $lexeme_data{'view'} },          'VBP';
    push @{ $lexeme_data{'visibly'} },       'RB';
    push @{ $lexeme_data{'we'} },            'PRP';
    push @{ $lexeme_data{'weak'} },          'JJ';
    push @{ $lexeme_data{'when'} },          'WRB';
    push @{ $lexeme_data{'which'} },         'WDT';
    push @{ $lexeme_data{'who'} },           'WP';
    push @{ $lexeme_data{'whole'} },         'NN';
    push @{ $lexeme_data{'whose'} },         'WP S';
    push @{ $lexeme_data{'will'} },          'MD';
    push @{ $lexeme_data{'with'} },          'IN';
    push @{ $lexeme_data{'works'} },         'NNS';
    push @{ $lexeme_data{'world'} },         'NN';
    push @{ $lexeme_data{'yet'} },           'RB';
    return \%lexeme_data;
} ## end sub setup_lexemes

package My_Nodes;
our $SELF;
sub new { return $SELF }

# vim: expandtab shiftwidth=4: