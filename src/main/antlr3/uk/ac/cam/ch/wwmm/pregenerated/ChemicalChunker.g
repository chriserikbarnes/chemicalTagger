grammar ChemicalChunker;

options {
    language=Java;
    output = AST;
   backtrack= true;
   memoize = true;
}
tokens{
Sentence;
Unmatched;
NounPhrase;
MultipleApparatus;
DissolvePhrase;
VerbPhrase;
CYCLES;
RATIO;
CITATION;
MIXTURE;
PrepPhrase;
TimePhrase;
RolePrepPhrase;
AtmospherePhrase;
TempPhrase;
AMOUNT;
MASS;
PERCENT;
VOLUME;
MOLAR;
PH;
EQUIVALENT;
YIELD;
APPARATUS;
MULTIPLE;
OSCARCM;
MOLECULE;
UNNAMEDMOLECULE;
QUANTITY;
PROCEDURE;
REFERENCETOCOMPOUND;
CaptionLabel;
}


@header {
    package uk.ac.cam.ch.wwmm.pregenerated;
 }
@lexer::header {package uk.ac.cam.ch.wwmm.pregenerated;}


@members {
public boolean isAtTokenPositionZero(TokenStream stream){
	return stream.index()==0;
}

public boolean followedByVBDorVBZthenVBYIELDed(TokenStream stream){
	String nextTokenTypeStr = stream.LT(1).getText();
	if ("VBD".equals(nextTokenTypeStr) || "VBZ".equals(nextTokenTypeStr)){
		String twoAheadTypeStr = stream.LT(3).getText();
		if ("VB-YIELD".equals(twoAheadTypeStr)){
			String twoAheadTokenText = stream.LT(4).getText();
			if (twoAheadTokenText !=null && twoAheadTokenText.toLowerCase().endsWith("ed")){
				return true;
			}
		}
	}
	return false;
}

public boolean cdHasRoleOtherThanIdentifier(TokenStream stream){
	String nextTokenTypeStr = stream.LT(1).getText();
	if (isQuantityUnit(nextTokenTypeStr)){
		return true;//quantity
	}
	if ("NN-TIMES".equals(nextTokenTypeStr)){
		return true;//e.g. washed with the compound 3 times
	}
	if ("COLON".equals(nextTokenTypeStr)){
		String twoAheadTypeStr = stream.LT(3).getText();
		if ("CD".equals(twoAheadTypeStr)){
			String threeAheadTypeStr = stream.LT(5).getText();
			if (!isQuantityUnit(threeAheadTypeStr)){
				return true;//ratio
			}
		}
	}
	return false;
}

public boolean followedByQuantityUnits(TokenStream stream){
	String nextTokenTypeStr = stream.LT(1).getText();
	return isQuantityUnit(nextTokenTypeStr);
}

public boolean isQuantityUnit(String tokenType){
	return ("NN-MOLAR".equals(tokenType) || "NN-AMOUNT".equals(tokenType) ||
			"NN-MASS".equals(tokenType) || "NN-VOL".equals(tokenType) ||
			"NN-EQ".equals(tokenType) || "NN-PERCENT".equals(tokenType));
}

public boolean precededByProduct(TokenStream stream){
	Token previousToken = stream.LT(-1);
	if (previousToken !=null && previousToken.getText().equalsIgnoreCase("product")){
		return true;
	}
	return false;
}

public boolean suitableVbYieldOrSynthesizeForReference(TokenStream stream){
	Token nextTokenType = stream.LT(1);
	if ("VB-YIELD".equals(nextTokenType.getText()) || "VB-SYNTHESIZE".equals(nextTokenType.getText())){
		String nextTokenText = stream.LT(2).getText();
		if (nextTokenText !=null && nextTokenText.toLowerCase().endsWith("ed")){
			return true;
		}
	}
	return false;
}

public boolean nextIsSemiColon(TokenStream stream){
	Token nextTokenType = stream.LT(1);
	if ("STOP".equals(nextTokenType.getText())){
		String nextTokenText = stream.LT(2).getText();
		if (nextTokenText !=null && nextTokenText.equals(";")){
			return true;
		}
	}
	return false;
}

public boolean notFollowedByBracketedYear(TokenStream stream){
	Token nextTokenType = stream.LT(1);
	if ("-LRB-".equals(nextTokenType.getText())){
		Token nextNextTokenType = stream.LT(3);
		if ("CD".equals(nextNextTokenType.getText())){
			String nextNextTokenText = stream.LT(4).getText();
			if (nextNextTokenText !=null){
				try{
					int i = Integer.parseInt(nextNextTokenText);
					if (i >1000){
						return false;
					}
				}
				catch (NumberFormatException e) {
				}
			}
		}
	}
	return true;
}
}

WS :  (' ')+ {skip();};
TOKEN : (~' ')+;



document: sentence+-> ^(Sentence  sentence )+ ;

sentence: (procedureNounPhrase | (sentenceStructure|unmatchedPhrase)+) stop*;

sentenceStructure:  (nounphrase|verbphrase|prepphrase|prepphraseAfter)+ (advAdj|colon)* (conjunction|rbconj|comma)*;

unmatchedPhrase
	:	 unmatchedToken -> ^(Unmatched unmatchedToken);

unmatchedToken //all base tokens other than stop
	:	(numeric|advAdj|tmunicode|cdunicode|jjcomp|inAll|
	nnexample|nnstate|nntime|nnmass|nnmolar|nnamount|nnatmosphere|nneq|nnvol|nnchementity|nntemp|nnph|nnflash|nngeneral|nnmethod|nnpressure|nncolumn|nnchromatography|nnvacuum|nncycle|nntimes|
	oscarcm|oscarase|verb|nnadd|nnmixture|nnapparatus|nnconcentrate|nndry|nnextract|nnfilter|nnprecipitate|nnpurify|nnremove|nnsynthesize|nnyield|colon|apost|neg|dash|percentsign|lsqb|rsqb|lrb|rrb|
	cc|dt|dtTHE|fw|md|nn|nns|nnp|prp|prp_poss|rbconj|sym|uh|clause|comma|ls|nnps|pos|nnidentifier);

procedureNounPhrase //only allowed at the start of the document
	: {isAtTokenPositionZero(input)}? headingProcedure  -> ^(NounPhrase  headingProcedure);

headingProcedure
	: headingProcedureRequiringTerminator headingProcedureTerminators | bracketedHeadingProcedure headingProcedureTerminators?;

headingProcedureRequiringTerminator
	: (nnidentifier|numeric) -> ^(PROCEDURE nnidentifier? numeric?);

bracketedHeadingProcedure
	: (bracketedIdentifier | bracketedNumeric | squareBracketedReference) -> ^(PROCEDURE bracketedIdentifier? bracketedNumeric? squareBracketedReference?);
	
	

headingProcedureTerminators
	: rrb|stop|colon;

nounphrase
	:	nounphraseStructure ->  ^(NounPhrase  nounphraseStructure);

nounphraseStructure
	:	nounphraseStructure1|nounphraseStructure2;
nounphraseStructure1
	:	 multiApparatus ->  ^(MultipleApparatus multiApparatus);
nounphraseStructure2
	:	dtTHE? dt? nounphraseContent  (conjunction* nounphraseContent {!followedByVBDorVBZthenVBYIELDed(input)}?)* (prepphraseOf| prepphraseIN)? ;

nounphraseContent
	: advAdj*  (dissolvePhrase|ratioOrBracketedRatio|noun|numeric|bracketedContent)+;

dissolvePhrase
	:	(dissolveStructure|lrb dissolveStructure rrb) ->  ^(DissolvePhrase lrb? dissolveStructure rrb?);

dissolveStructure
	:	adj? (nnp nnchementity |nnp?(molecule|unnamedmolecule)) inMolecule (conjunction molecule)* ;

inMolecule
	: inin dtTHE? adj? nnp? (molecule|unnamedmolecule);

verbphrase
	:	verbphraseStructure ->  ^(VerbPhrase  verbphraseStructure);
//Would this be better written in terms of auxillary verbs and normal verbs? e.g. auxillary+ verb?
verbphraseStructure :  dt? to? inAll? inafter? md* rbconj? adv* adj? (actionVerb md* adv* adj? neg?  | otherVerb md* adv* adj? neg? otherVerbStructure* actionVerbStructure?) inoff? (cc? comma? prepphrase)* ;

actionVerbStructure: md* rbconj? adv* adj? actionVerb md* adv* adj? neg? ;
otherVerbStructure: md* rbconj? adv* adj? otherVerb md* adv* adj? neg? ;

verb: actionVerb | otherVerb;
actionVerb : vbadd|vbcharge|vbcontain|vbdilute|vbdrop|vbfill|vbtreat|vbapparatus|vbconcentrate|vbcool|vbdegass|degassMultiVerb|vbsubject|vbdissolve|vbdry|vbextract|vbfilter|vbheat|vbincrease|vbsubmerge|vbpartition|vbprecipitate|vbpurify|vbquench|vbrecover|vbremove|vbstir|vbsynthesize|vbwait|vbwash|vbyield;
otherVerb : vb|vbd|vbg|vbn|vbp|vbz|vbchange|vbimmerse|vbsuspend|vbuse;

degassMultiVerb
	:	vbdegass cc vbfill;

noun 	:	nounStructure (dash nounStructure)*;

nounStructure :  prp|prp_poss|captionLabel|nnplabel|citation|cycles|molecule|apparatus|unnamedmolecule|nnstate|procedureNode|nn|nns|nnp|nnadd|preparationphrase|nnexample|range|nntime|nnatmosphere|tmunicode|quantity|nnchementity|nntemp|nnph|nnflash|nngeneral|nnamount|nneq|nnpressure|nncolumn|nnchromatography|nnvacuum|nncycle|nntimes|nnconcentrate|nnvol|nnpurify|nnsynthesize|nnmixture|squareBracketedReference|nndry|nnextract|nnfilter|nnprecipitate|nnremove|nnyield|fw|sym|clause|ls|nnps|pos|oscarase;

// Different PrepPhrases

prepphrase
	: 	neg? (prepphraseAtmosphere|prepphraseTime|prepphraseTemp|prepphraseIN|prepphraseRole|prepphraseOther)  ;

prepphraseAtmosphere
	: prepphraseAtmosphereContent ->  ^(AtmospherePhrase  prepphraseAtmosphereContent ) ;

prepphraseAtmosphereContent
	:inunder  dt? advAdj* molecule nnatmosphere?	;

prepphraseTime
	:prepPhraseTimeStructure ->  ^(TimePhrase  prepPhraseTimeStructure);

prepPhraseTimeStructure
	:advAdj* inAll?  dt? advAdj* cd? nntime+	;

prepphraseTemp:  prepphraseTempContent ->  ^(TempPhrase   prepphraseTempContent);

prepphraseTempContent
	:  advAdj? inAll? dt? advAdj? cd? nntemp+;

prepphraseIN
	:inin molecule ->  ^(PrepPhrase  inin  molecule);

prepphraseRole
	:inas dt? nnchementity ->	^(RolePrepPhrase  inas dt? nnchementity);

prepphraseOther
	: advAdj* inMost+  nounphrase ->  ^(PrepPhrase  advAdj* inMost+  nounphrase);

prepphraseOf
	: inof  nounphrase->  ^(PrepPhrase  inof  nounphrase);

prepphraseAfter
	:  advAdj? inafter  nounphrase ->  ^(PrepPhrase  advAdj* inafter  nounphrase);

preparationphrase
	: vbsynthesize inas (nnexample cd| prepphrase)	;

multiApparatus
	:	apparatus (conjunction* apparatus )*;
apparatus
	:	dt? preapparatus* nnApp+-> ^(APPARATUS   dt? preapparatus* nnApp+ );

nnApp
	:	nnapparatus+ (dash nnapparatus)*;
preapparatus
	:    (quantity|adj|nnpressure|nnadd|molecule|nnchementity|nnstate|nn)+ ;

oscarCompound :  (jjcomp|adj)* oscarCompoundStructure adj? nnstate? (numericReferenceOrQuantity | nnchementity )? quantity* fromProcedure?;

oscarCompoundStructure: (oscarcm+ afterOscarCompoundStructure? | bracketedOscarCompoundStructure) -> ^(OSCARCM oscarcm* afterOscarCompoundStructure? bracketedOscarCompoundStructure?);
afterOscarCompoundStructure: (dash oscarcm+)+ dash?|((colon oscarcm+)+ lrb? ratio)=>(colon oscarcm+)+|(dash|apost)+;
bracketedOscarCompoundStructure :	lrb  oscarcm+ rrb;

molecule
	:  moleculeamount-> ^(MOLECULE  moleculeamount );

moleculeamount : (moleculeamount3| moleculeamount1 | moleculeamount2) asAstate? ;

moleculeamount3
	:(quantity|bracketedContentInMol)+ inof (dtTHE | dt)? ratioOrBracketedRatio bracketedContentInMol? oscarCompound ;

moleculeamount1
	:(nnchementity | nnstate)? (quantity|bracketedContentInMol)+ inof (quantity inof?)? (dtTHE | dt)? oscarCompound+ afterCompoundCitationOrQuantity;

moleculeamount2
	:(quantity|bracketedContentInMol)* oscarCompound+ afterCompoundCitationOrQuantity;

afterCompoundCitationOrQuantity: (citation|quantity|comma (quantity1Node|citationStructure)|bracketedContentInMol)*;

unnamedmolecule
	: unnamedmoleculeDescription -> ^(UNNAMEDMOLECULE unnamedmoleculeDescription);

unnamedmoleculeDescription
	:	unnamedmoleculeDescriptionStart afterCompoundCitationOrQuantity asAstate?;

unnamedmoleculeDescriptionStart
	:	quantityOf (potentialUnnamedMoleculeAmount1 | potentialUnnamedMoleculeAmount2 | definiteUnnamedMolecule ) | potentialUnnamedMoleculeAmount2 | definiteUnnamedMolecule;

quantityOf
	:	quantity+ inof? (dtTHE | dt)?;

potentialUnnamedMoleculeAmount1
	: potentialUnnamedMolecule quantity* asAstate? fromProcedure?;

potentialUnnamedMoleculeAmount2
	: (numberCompoundReference (quantity | asAstate ) | potentialUnnamedMoleculeStructureNN (numericReferenceOrQuantity | asAstate | fromProcedure) ) quantity* asAstate? fromProcedure?;

definiteUnnamedMolecule
	:	definiteUnnamedMoleculeStructure quantity* asAstate? fromProcedure?;

definiteUnnamedMoleculeStructure
	: adj* (nnchementity numericOrIdentifierCompoundReference | jjcomp nnchementity numericReferenceOrQuantity?) | alphanumericOrIdentifierCompoundReference;

potentialUnnamedMolecule
	: numberCompoundReference | potentialUnnamedMoleculeStructureNN numericReferenceOrQuantity?  ;

potentialUnnamedMoleculeStructureNN
	:	(jj|jjchem|oscarcj|jjcomp)* (nnstate|referenceToExampleCompound|nnatmosphere|nnmixture|oscarase) | (jj|jjchem|oscarcj)* nnchementity;

//This rule is neccesary as otherwise the parser will greedily split up a quantity into a reference and unmatched unit
numericReferenceOrQuantity
	:	quantity | numericOrIdentifierCompoundReference;

asAstate
	: inas dt? (jj|jjchem|oscarcj)* nnstate quantity*;

alphanumericOrIdentifierCompoundReference
  : allIdentifierTypesOtherThanCD -> ^(REFERENCETOCOMPOUND allIdentifierTypesOtherThanCD);

numberCompoundReference
  : (cd {!cdHasRoleOtherThanIdentifier(input)}?) -> ^(REFERENCETOCOMPOUND cd);

numericOrIdentifierCompoundReference
  : allIdentifierTypes -> ^(REFERENCETOCOMPOUND allIdentifierTypes );

captionLabel
   : captionLabelContent+ -> ^(CaptionLabel captionLabelContent+);
captionLabelContent
   : (nnplabel allIdentifierTypes (conjunction allIdentifierTypes)*);

quantity 	:  (quantity1Node|quantity2Node);

quantity1Node : quantity1 ->   ^(QUANTITY  quantity1);

quantity1
	: lrb measurements (comma  measurements)* (comma preparationphrase)* (stop preparationphrase)*  rrb;

quantity2Node : quantity2 ->   ^(QUANTITY  quantity2);

quantity2
	:  measurements (comma  measurements)*  ;

measurements
	:(cd nn)? (multiple|measurementtypes) dt?;
multiple	: cd cdunicode measurementtypes? -> ^(MULTIPLE   cd cdunicode measurementtypes? );
measurementtypes
	: molar|amount|mass|volume|logHydrogenActivity|equivalent|yield|percent;

molar	: cd nnmolar -> ^(MOLAR   cd nnmolar );
amount	: cd nnamount -> ^(AMOUNT   cd nnamount );
mass	: cd nnmass-> ^(MASS   cd nnmass );
volume	: cd nnvol -> ^(VOLUME   cd nnvol );
logHydrogenActivity	: nnph sym? cd -> ^(PH nnph sym? cd );
equivalent: cd nneq -> ^(EQUIVALENT cd nneq );
yield: yield1 -> ^(YIELD yield1)| yield2 -> ^(YIELD yield2);
yield1: nnyield (inof|colon) percent;
yield2: percent nnyield ;
percent	: cd nn? percentsign ( dash cd percentsign)? -> ^(PERCENT   cd nn? percentsign dash? cd? percentsign?);//the nn? allows "10 wt %"

//Different expressions are needed in and outside molecules as within a molecule other "molecules" are likely to be synoymns rather than entities in their own right
bracketedContent: ratio?  (bracketedContent1|bracketedContent2|bracketedContent3) -> ^(MIXTURE ratio? bracketedContent1? bracketedContent2? bracketedContent3?);
bracketedContent1: comma lrb bracketedContentContents rrb comma;
bracketedContent2: lrb bracketedContentContents rrb;
bracketedContent3: lsqb bracketedContentContents rsqb;
bracketedContentContents: (verb|noun|bracketedContent|md|percentsign|dash|inAll|ratio|conjunction|adj|colon|stop|numeric)+;

bracketedContentInMol: ratio?  (bracketedContentInMolStructure1|bracketedContentInMolStructure2) -> ^(MIXTURE ratio? bracketedContentInMolStructure1? bracketedContentInMolStructure2?);
bracketedContentInMolStructure1: comma bracketedContentInMolStructure2 comma;
bracketedContentInMolStructure2: lrb bracketedContentInMolContents1 bracketedContentInMolContents2* rrb|lsqb bracketedContentInMolContents1 bracketedContentInMolContents2* rsqb;
bracketedContentInMolContents1: numberCompoundReference (comma | colon | {nextIsSemiColon(input)}? stop)|bracketedContentInMolContentsAlwaysAllowed;
bracketedContentInMolContents2: cc | bracketedContentInMolContentsAlwaysAllowed ;
bracketedContentInMolContentsAlwaysAllowed: verb|quantity2Node|oscarCompound|alphanumericOrIdentifierCompoundReference|ratio|cd|md|percentsign|dash|inAll|comma|adj|colon|stop|noun|bracketedContentInMol;

fromProcedure: (infrom | {precededByProduct(input)}? inof | {suitableVbYieldOrSynthesizeForReference(input)}? (vbyield|vbsynthesize) (inin|inby|infrom)) procedureNode;

procedureNode: method -> ^(PROCEDURE method);

method:
    ((nngeneral|nn)? nnmethod allIdentifierTypes? | nnexample allIdentifierTypes) ( (comma |colon |inof | infrom)? submethod | lrb submethod rrb)*;

submethod : (nnmethod|nnexample) allIdentifierTypes;

referenceToExampleCompound :
	nnexample allIdentifierTypes -> ^(REFERENCETOCOMPOUND nnexample allIdentifierTypes);

advAdj
	:adv|adj;

range: numeric dash numeric;
cycles	:	cycleStructure -> ^(CYCLES cycleStructure)  ;
cycleStructure	:	cd dashNN? nncycle;
dashNN	:	(adj|nn|cd) (dash (adj|nn|cd))*;

ratioOrBracketedRatio : lrb ratio rrb | ratio;
ratio : cdRatio -> ^(RATIO cdRatio);
cdRatio : cd (colon cd {!followedByQuantityUnits(input)}?)+;

citation:  citationStructure|comma citationContent comma;

citationStructure:  citationContent -> ^(CITATION citationContent);
citationContent:   lrb (nnp|fw|cd|conjunction) (nnp|fw|cd|conjunction)+ rrb ;


allIdentifierTypes : allIdentifierTypesOtherThanCD | cd {!cdHasRoleOtherThanIdentifier(input)}?;
allIdentifierTypesOtherThanCD : squareBracketedReference|identifierOrBracketedIdentifier|cdAlphanum|{notFollowedByBracketedYear(input)}?bracketedNumeric;
numericOrBracketedNumeric	:  numeric | bracketedNumeric;
bracketedNumeric	:  lrb numeric rrb;
squareBracketedReference :	lsqb numeric rsqb;
identifierOrBracketedIdentifier : cd? nnidentifier | bracketedIdentifier;
bracketedIdentifier	:  lrb cd? nnidentifier rrb;

adj	:	jj|jjr|jjs|jjchem|oscarcj|oscarrn;
adv	:	rb|rbr|rp|rbs;
clause	:	wdt|wp_poss|wrb|ex|pdt|wp;
conjunction :	cc|comma;
inAll	: in|inafter|inas|inbefore|inby|infor|infrom|inin|ininto|inof|inoff|inon|inover|inunder|invia|inwith|inwithout|to;
inMost	: in|inas|inbefore|inby|infor|infrom|inin|ininto|inof|inoff|inon|inover|inunder|invia|inwith|inwithout|to;
numeric : cd|cdAlphanum;


//Tags---Pattern---Description

nnplabel:'NNP-LABEL' TOKEN -> ^('NNP-LABEL' TOKEN);

cdAlphanum:'CD-ALPHANUM' TOKEN -> ^('CD-ALPHANUM' TOKEN);
oscarcj:'OSCAR-CJ' TOKEN -> ^('OSCAR-CJ' TOKEN);
oscarrn:'OSCAR-RN' TOKEN -> ^('OSCAR-RN' TOKEN);
oscarase:'OSCAR-ASE' TOKEN -> ^('OSCAR-ASE' TOKEN);
tmunicode:'TM-UNICODE' TOKEN -> ^('TM-UNICODE' TOKEN);
cdunicode:'CD-UNICODE' TOKEN -> ^('CD-UNICODE' TOKEN);
jjchem:'JJ-CHEM' TOKEN -> ^('JJ-CHEM' TOKEN);
jjcomp:'JJ-COMPOUND' TOKEN -> ^('JJ-COMPOUND' TOKEN);
// Prepositions
inas:'IN-AS' TOKEN -> ^('IN-AS' TOKEN);
inbefore:'IN-BEFORE' TOKEN -> ^('IN-BEFORE' TOKEN);
inafter:'IN-AFTER' TOKEN -> ^('IN-AFTER' TOKEN);
inin:'IN-IN' TOKEN -> ^('IN-IN' TOKEN);
ininto:'IN-INTO' TOKEN -> ^('IN-INTO' TOKEN);
inwith:'IN-WITH' TOKEN -> ^('IN-WITH' TOKEN);
inwithout:'IN-WITHOUT' TOKEN -> ^('IN-WITHOUT' TOKEN);
inby:'IN-BY' TOKEN -> ^('IN-BY' TOKEN);
invia:'IN-VIA' TOKEN -> ^('IN-VIA' TOKEN);
inof:'IN-OF' TOKEN -> ^('IN-OF' TOKEN);
inon:'IN-ON' TOKEN -> ^('IN-ON' TOKEN);
infor:'IN-FOR' TOKEN -> ^('IN-FOR' TOKEN);
infrom:'IN-FROM' TOKEN -> ^('IN-FROM' TOKEN);
inunder:'IN-UNDER' TOKEN -> ^('IN-UNDER' TOKEN);
inover:'IN-OVER' TOKEN -> ^('IN-OVER' TOKEN);
inoff:'IN-OFF' TOKEN -> ^('IN-OFF' TOKEN);

//Modified Nouns
nnstate:'NN-STATE' TOKEN -> ^('NN-STATE' TOKEN);
nntime:'NN-TIME' TOKEN -> ^('NN-TIME' TOKEN);
nnmass:'NN-MASS' TOKEN -> ^('NN-MASS' TOKEN);
nnamount:'NN-AMOUNT' TOKEN -> ^('NN-AMOUNT' TOKEN);
nnmolar:'NN-MOLAR' TOKEN -> ^('NN-MOLAR' TOKEN);
nnatmosphere:'NN-ATMOSPHERE' TOKEN -> ^('NN-ATMOSPHERE' TOKEN);
nneq:'NN-EQ' TOKEN -> ^('NN-EQ' TOKEN);
nnvol:'NN-VOL' TOKEN -> ^('NN-VOL' TOKEN);
nnchementity:'NN-CHEMENTITY' TOKEN -> ^('NN-CHEMENTITY' TOKEN);
nntemp:'NN-TEMP' TOKEN -> ^('NN-TEMP' TOKEN);
nnph:'NN-PH' TOKEN -> ^('NN-PH' TOKEN);
nnflash:'NN-FLASH' TOKEN -> ^('NN-FLASH' TOKEN);
nngeneral:'NN-GENERAL' TOKEN -> ^('NN-GENERAL' TOKEN);
nnmethod:'NN-METHOD' TOKEN -> ^('NN-METHOD' TOKEN);
nnpressure:'NN-PRESSURE' TOKEN -> ^('NN-PRESSURE' TOKEN);
nncolumn:'NN-COLUMN' TOKEN -> ^('NN-COLUMN' TOKEN);
nnchromatography:'NN-CHROMATOGRAPHY' TOKEN -> ^('NN-CHROMATOGRAPHY' TOKEN);
nnvacuum:'NN-VACUUM' TOKEN -> ^('NN-VACUUM' TOKEN);
nncycle:'NN-CYCLE' TOKEN -> ^('NN-CYCLE' TOKEN);
nntimes:'NN-TIMES' TOKEN -> ^('NN-TIMES' TOKEN);
nnexample:'NN-EXAMPLE' TOKEN -> ^('NN-EXAMPLE' TOKEN);

//A word of a chemical identified by OSCAR
oscarcm:'OSCAR-CM' TOKEN -> ^('OSCAR-CM' TOKEN);

//Verbs
vbuse:'VB-USE' TOKEN -> ^('VB-USE' TOKEN);
vbchange:'VB-CHANGE' TOKEN -> ^('VB-CHANGE' TOKEN);
vbsubmerge:'VB-SUBMERGE' TOKEN -> ^('VB-SUBMERGE' TOKEN);
vbsubject:'VB-SUBJECT' TOKEN -> ^('VB-SUBJECT' TOKEN);

//Add Tokens
nnadd:'NN-ADD' TOKEN -> ^('NN-ADD' TOKEN);
nnmixture:'NN-MIXTURE' TOKEN -> ^('NN-MIXTURE' TOKEN);
vbdilute:'VB-DILUTE' TOKEN -> ^('VB-DILUTE' TOKEN);
vbadd:'VB-ADD' TOKEN -> ^('VB-ADD' TOKEN);
vbcharge:'VB-CHARGE' TOKEN -> ^('VB-CHARGE' TOKEN);
vbcontain:'VB-CONTAIN' TOKEN -> ^('VB-CONTAIN' TOKEN);
vbdrop:'VB-DROP' TOKEN -> ^('VB-DROP' TOKEN);
vbfill:'VB-FILL' TOKEN -> ^('VB-FILL' TOKEN);
vbsuspend:'VB-SUSPEND' TOKEN -> ^('VB-SUSPEND' TOKEN);
vbtreat:'VB-TREAT' TOKEN -> ^('VB-TREAT' TOKEN);

//Apparatus Tokens
vbapparatus:'VB-APPARATUS' TOKEN -> ^('VB-APPARATUS' TOKEN);
nnapparatus:'NN-APPARATUS' TOKEN -> ^('NN-APPARATUS' TOKEN);

//Concentrate Tokens
vbconcentrate:'VB-CONCENTRATE' TOKEN -> ^('VB-CONCENTRATE' TOKEN);
nnconcentrate:'NN-CONCENTRATE' TOKEN -> ^('NN-CONCENTRATE' TOKEN);

//Cool Tokens
vbcool:'VB-COOL' TOKEN -> ^('VB-COOL' TOKEN);

//Degass Tokens
vbdegass:'VB-DEGASS' TOKEN -> ^('VB-DEGASS' TOKEN);

//Dissolve Tokens
vbdissolve:'VB-DISSOLVE' TOKEN -> ^('VB-DISSOLVE' TOKEN);

//Dry Tokens
vbdry:'VB-DRY' TOKEN -> ^('VB-DRY' TOKEN);
nndry:'NN-DRY' TOKEN -> ^('NN-DRY' TOKEN);

//Extract Tokens
vbextract:'VB-EXTRACT' TOKEN -> ^('VB-EXTRACT' TOKEN);
nnextract:'NN-EXTRACT' TOKEN -> ^('NN-EXTRACT' TOKEN);

//Filter Tokens
vbfilter:'VB-FILTER' TOKEN -> ^('VB-FILTER' TOKEN);
nnfilter:'NN-FILTER' TOKEN -> ^('NN-FILTER' TOKEN);

//Heat Tokens
vbheat:'VB-HEAT' TOKEN -> ^('VB-HEAT' TOKEN);
vbincrease:'VB-INCREASE' TOKEN -> ^('VB-INCREASE' TOKEN);

//Immerse tokens
vbimmerse:'VB-IMMERSE' TOKEN -> ^('VB-IMMERSE' TOKEN);

//Partition Tokens
vbpartition:'VB-PARTITION' TOKEN -> ^('VB-PARTITION' TOKEN);

//Precipitate Tokens
vbprecipitate:'VB-PRECIPITATE' TOKEN -> ^('VB-PRECIPITATE' TOKEN);
nnprecipitate:'NN-PRECIPITATE' TOKEN -> ^('NN-PRECIPITATE' TOKEN);

//Purify Tokens
vbpurify:'VB-PURIFY' TOKEN -> ^('VB-PURIFY' TOKEN);
nnpurify:'NN-PURIFY' TOKEN -> ^('NN-PURIFY' TOKEN);

//Quench Tokens
vbquench:'VB-QUENCH' TOKEN -> ^('VB-QUENCH' TOKEN);

//Recover Tokens
vbrecover:'VB-RECOVER' TOKEN -> ^('VB-RECOVER' TOKEN);

//Remove Tokens
vbremove:'VB-REMOVE' TOKEN -> ^('VB-REMOVE' TOKEN);
nnremove:'NN-REMOVE' TOKEN -> ^('NN-REMOVE' TOKEN);

//Stir Tokens
vbstir:'VB-STIR' TOKEN -> ^('VB-STIR' TOKEN);

//Synthesize Tokens
vbsynthesize:'VB-SYNTHESIZE' TOKEN -> ^('VB-SYNTHESIZE' TOKEN);
nnsynthesize:'NN-SYNTHESIZE' TOKEN -> ^('NN-SYNTHESIZE' TOKEN);

//Wait Tokens
vbwait:'VB-WAIT' TOKEN -> ^('VB-WAIT' TOKEN);

//Wash Tokens
vbwash:'VB-WASH' TOKEN -> ^('VB-WASH' TOKEN);

//Yield Tokens
vbyield:'VB-YIELD' TOKEN -> ^('VB-YIELD' TOKEN);

//Yield Tokens
nnyield:'NN-YIELD' TOKEN -> ^('NN-YIELD' TOKEN);

//Misc Tokens mainly to replace characters that are not markup friendly
// Conjunctive Adverbs
rbconj:'RB-CONJ' TOKEN -> ^('RB-CONJ' TOKEN);
colon:'COLON' TOKEN -> ^('COLON' TOKEN);
comma:'COMMA' TOKEN -> ^('COMMA' TOKEN);
apost:'APOST' TOKEN -> ^('APOST' TOKEN);
neg:'NEG' TOKEN -> ^('NEG' TOKEN);
dash:'DASH' TOKEN -> ^('DASH' TOKEN);
stop:'STOP' TOKEN -> ^('STOP' TOKEN);
percentsign:'NN-PERCENT' TOKEN -> ^('NN-PERCENT' TOKEN);
lsqb:'LSQB' TOKEN -> ^('LSQB' TOKEN);
rsqb:'RSQB' TOKEN -> ^('RSQB' TOKEN);

nnidentifier:'NN-IDENTIFIER' TOKEN -> ^('NN-IDENTIFIER' TOKEN);

//The determiner 'the';
dtTHE:'DT-THE' TOKEN -> ^('DT-THE' TOKEN);

lrb:'-LRB-' TOKEN -> ^('-LRB-' TOKEN);
rrb:'-RRB-' TOKEN -> ^('-RRB-' TOKEN);

//Penn Treebank Tokens

// Coordinating conjunction (and, or)
cc:'CC' TOKEN -> ^('CC' TOKEN);

// Cardinal numeral (one, two, 2, etc.)
cd:'CD' TOKEN -> ^('CD' TOKEN);

// Singular determiner/quantifier (this, that)
dt:'DT' TOKEN -> ^('DT' TOKEN);

// Existential there
ex:'EX' TOKEN -> ^('EX' TOKEN);

// Foreign word (hyphenated before regular tag)
fw:'FW' TOKEN -> ^('FW' TOKEN);

// Preposition
in:'IN' TOKEN -> ^('IN' TOKEN);

// Adjective
jj:'JJ' TOKEN -> ^('JJ' TOKEN);

// Comparative adjective
jjr:'JJR' TOKEN -> ^('JJR' TOKEN);

// Semantically superlative adjective (chief, top)
jjs:'JJS' TOKEN -> ^('JJS' TOKEN);

// List item marker
ls:'LS' TOKEN -> ^('LS' TOKEN);

// Modal auxiliary (can, should, will)
md:'MD' TOKEN -> ^('MD' TOKEN);

// Singular or mass noun
nn:'NN' TOKEN -> ^('NN' TOKEN);

// Plural noun
nns:'NNS' TOKEN -> ^('NNS' TOKEN);

// Proper noun or part of name phrase
nnp:'NNP' TOKEN -> ^('NNP' TOKEN);

// Proper noun, plural
nnps:'NNPS' TOKEN -> ^('NNPS' TOKEN);

//Predeterminer
pdt:'PDT' TOKEN -> ^('PDT' TOKEN);

// Possessive ending
pos:'POS' TOKEN -> ^('POS' TOKEN);

//Personal pronoun
prp:'PRP' TOKEN -> ^('PRP' TOKEN);

//Possessive pronoun
prp_poss:'PRP$' TOKEN -> ^('PRP$' TOKEN);

// Adverb
rb:'RB' TOKEN -> ^('RB' TOKEN);

// Comparative adverb
rbr:'RBR' TOKEN -> ^('RBR' TOKEN);

// Superlative adverb
rbs:'RBS' TOKEN -> ^('RBS' TOKEN);

// Adverb/particle (about, off, up)
rp:'RP' TOKEN -> ^('RP' TOKEN);

// Symbol
sym:'SYM' TOKEN -> ^('SYM' TOKEN);

// Infinitive marker to
to:'TO' TOKEN -> ^('TO' TOKEN);

// Interjection, exclamation
uh:'UH' TOKEN -> ^('UH' TOKEN);

// Verb, base form
vb:'VB' TOKEN -> ^('VB' TOKEN);

// Verb, past tense
vbd:'VBD' TOKEN -> ^('VBD' TOKEN);

// Verb, present participle/gerund
vbg:'VBG' TOKEN -> ^('VBG' TOKEN);

// Verb, past participle
vbn:'VBN' TOKEN -> ^('VBN' TOKEN);

// Verb, non-3rd person singular present
vbp:'VBP' TOKEN -> ^('VBP' TOKEN);

// Verb, 3rd. singular present
vbz:'VBZ' TOKEN -> ^('VBZ' TOKEN);

// Wh- determiner (which, that)
wdt:'WDT' TOKEN -> ^('WDT' TOKEN);

// wh- pronoun (what, who, whom)
wp:'WP' TOKEN -> ^('WP' TOKEN);

// Possessive wh- pronoun (whose)
wp_poss:'WP$' TOKEN -> ^('WP$' TOKEN);

// Wh- adverb (how, where, when)
wrb:'WRB' TOKEN -> ^('WRB' TOKEN);
