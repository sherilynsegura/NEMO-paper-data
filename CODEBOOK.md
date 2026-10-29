# Data codebook

Definitions cover all 66 columns in `data/nemo_analysis_data.csv`, using the supplied codebook, author clarifications and processing documentation. Observed values describe the dataset; they do not define valid scale ranges.

Each row is a participant's trial. Questionnaire responses may repeat across trials and family members; summarize once per participant.

`NA` includes measures that were not collected in a particular wave, missing responses, and undefined adjustment scores. Treat coopSports=99 as a non-response for that item.

## Link observations

Use `ppt` for participant trials, `group` for sessions and family pairing in waves 1–8, and `dyad` for family pairing in waves 9–10. `subjectNr` identifies the tablet/position within the testing room. Read numeric IDs as identifiers.

## Interpret sources

Source 0 is anonymous (wave 2); 1 is the family member; 2 is another adult; 3 is another child. For children, sources 1/2/3 are vertical/oblique/horizontal; for caregivers, they are vertical/horizontal/oblique. Analyses generally classify age ≤18 as child and >18 as caregiver.

## Variable dictionary

`codebook.csv` adds observed values, nonmissing wave coverage and missing-row counts. Missing counts include literal NA/empty fields, not item-specific nonresponse codes. Source-year headings identify variable introductions rather than complete wave coverage.

| Variable | Description | Scale / coding | Respondent | Item wording / legend | Notes |
| --- | --- | --- | --- | --- | --- |
| wave_source | Original collection-wave label | 2021; 2022; 2023-1; 2023-2; 2024-1; 2024-2; 2024-3; 2025-1; 2025-2; 2025-3 | system |  | Maps to wave 1–10 in chronological order. |
| wave | Sequential collection-wave number | Integer 1–10 | system | wave number | Collection-year labels are stored separately in wave_source. |
| group | Unique group identifier | integer | system | unique group number |  |
| ppt | Unique participant identifier | integer | system | unique participant number |  |
| age | Age of participant | years | system | age of participant |  |
| sex | Sex of participant | 1=male; 2=female; 3=other | system | sex of participant (1=male; 2=female; 3=other) |  |
| seatingType | Seating arrangement | 1=face-to-face; 2=facing away; 3=divider | system | 1=face to face; 2=facing away; 3=divider wall |  |
| period | Period in the game | integer | system | period in the game |  |
| choseSource | Whether a social source could be selected | 0=assigned source; 1=participant could choose source | system | could source be selected by ppt? |  |
| socialSource | Type of social source | 0=unknown; 1=group mate; 2=other adult; 3=other child | system | 0=unknown to participant; 1=group mate; 2=other adult; 3=other child |  |
| nAnimals | Correct number of animals in the round | integer | task | correct number of animals in this round |  |
| firstEstimate | Initial estimate before social info | numeric, 1-150 | participant | firstEstimate |  |
| socialInfo | Information provided by social source | numeric | system | socialInfo |  |
| secondEstimate | Estimate after social info | numeric, 1-150 | participant | secondEstimate |  |
| sourceAge | Age of social source (child only) | years | system | NA for adult sources | NA for adult sources |
| competenceLadder | Self-efficacy ladder rating | 0–10 ladder | participant | self efficacy (click on stick figure on ladder: 1=low; 10=high) |  |
| trust | General interpersonal trust | 1–7 Likert | participant | "Do you agree with this statement? I see myself as someone who generally trusts other people." (1=disagree strongly; 7=agree strongly) | Single-item |
| independence | Importance of child independence | 1–7 slider | parent | parent-rated emphasis on... independence |  |
| obedience | Importance of child obedience | 1–7 slider | parent | … obedience |  |
| PSQ_equal | Treat child as equal family member | 1–7 slider | parent | I treat my child as an equal member of the family. (slider, 1=never; 7=always) |  |
| PSQ_isayso | Authoritarian justification style | 1–7 slider | parent | When my child asks me why he/she has to do something, I tell him/her: "because I said so", "because I am your parent", or "because that is what I want". (slider, 1=never; 7=always) |  |
| competenceLadderOther | Rated efficacy of other group member | 1–10 | participant | rated efficacy of the other in the group (click on stick figure on ladder: 1=low; 10=high) |  |
| IOS | Inclusion of Other in Self | 1–7 pictorial | participant | Which picture best describes your relationship with the people whose guesses you saw? |  |
| PSQ_responsible | Emphasis on responsibility | 1–7 | parent | … own responsibility, 1-7 |  |
| ageOther | Age of other dyad member | years | system | age of the other particpant in the group |  |
| sexOther | Sex of other dyad member | 1=male; 2=female; 3=other | system | sex of the other participant in the group (1=male, 2=female, 3=other) |  |
| treatment | Assigned social-source condition (Wave 4) | 1=assigned other child; 2=assigned other adult | system |  | Wave 4 (2023-2) only. Proposed source-condition mapping matches every nonmissing record: 1 corresponds to socialSource=3; 2 to socialSource=2. Use socialSource for comparisons across waves. |
| shownAge | Age shown for social source (child only) | years | system | age of the social source (for social source=child: age; for social source=adult: NA) - should be matched with age of child in the pair | Matched to child age |
| IOS_otherChildren | IOS with age-mates | 1–7 pictorial | child | inclusion of the other in the self, with age-mates |  |
| PSQ2_strictRules | Strict rule enforcement | 1–7 slider | parent | I impose strict rules on my children without considering their opinion (slider, 1 = never, 7 = always) | Same item: PSQ2_strictRules in wave 5; PSQ_strictRules in wave 6. Combine by wave when pooling. |
| PSQ_strictRules | Strict rule enforcement (alternate column name) | 1–7 slider | parent | I impose strict rules on my children without considering their opinion (slider, 1 = never, 7 = always) | Same item: PSQ2_strictRules in wave 5; PSQ_strictRules in wave 6. Combine by wave when pooling. |
| genderChild | Child gender | 1=male; 2=female; 3=other | system |  |  |
| genderParent | Parent gender | 1=male; 2=female; 3=other | system |  |  |
| ageParent | Parent age | years | system |  |  |
| ageChild | Child age | years | system |  |  |
| selfEsteemParent | Child self-esteem | 1-7 ladder | parent | self esteem of child, parent rating on ladder |  |
| selfEsteemChild | Self-esteem | 1-7 ladder | child | self esteem of child, self rated on ladder |  |
| agreeParent | Child agreeableness | 2-14 TIPI | parent | agreeableness of child, rated by parent with TIPI, 2-14 | Scale: 2–14. |
| agreeChild | Agreeableness | 1-10 pictorial | child | agreeableness of child, rated with pictorial questionnaire |  |
| consciParent | Child conscientiousness | 2-14 TIPI | parent | conscientiousness of child, rated by parent with TIPI, 2-14 | Scale: 2–14. |
| consciChild | Conscientiousness | 1-10 pictorial | child | conscientiousness of child, rated with pictorial questionnaire |  |
| extravParent | Child extraversion | 2-14 TIPI | parent | extraversion of child, rated by parent with TIPI, 2-14 | Scale: 2–14. |
| extravChild | Extraversion | 1-10 pictorial | child | extraversion of child, rated with pictorial questionnaire |  |
| schooltype | School type | 1=traditional; 2=free/alternative; 3=other | parent | 1=traditional; 2=free/alternative; 3=other |  |
| coopSchool | Cooperation at school | 1–4 | parent | degree of cooperation at school (1 = low, 4 = high) |  |
| coopSports | Cooperation in sports | 1–4 | parent | degree of cooperation at sports (1 = low, 4 = high) | Optional item: 99 means not completed. Treat 99 as missing for analysis; stored values are unchanged. |
| parentanswerTeamSport | Child sport participation | 1 = yes; 2 = no my child does not do a team sport; 3 = no physical sport | parent | does your child do a team sport? (1 = yes, 2 = no my child does not do a team sport, 3 = no physical sport) |  |
| olderSibs | Number of older siblings | integer | parent | number of older siblings of the child |  |
| youngerSibs | Number of younger siblings | integer | parent | number of younger siblings of the child |  |
| dyad | Unique family dyad identifier | integer | system | family within the session (unique numbers; based on variable "group", with "1" or "2" appended) | Family ID in waves 9–10, constructed from group with a suffix. Use group for family matching in waves 1–8 and dyad in waves 9–10. |
| subjectNr | Within-room subject/tablet number | 1–4 | system |  | Subject/tablet number in waves 9–10, with two dyads per room. Use ppt for participant identity and dyad for family pairing. |
| IOS_parents | Parent-rated IOS | 1-7 pictorial | parent | Which picture best describes your relationship with your child (with whom you just played this game)? | Same item: IOS_parents in wave 9; IOS_parent in wave 10. Combine by wave when pooling. |
| siblingsChild | Sibling-related item | Observed 1; 2 | requires confirmation |  | Codes 1/2 are undocumented. Not used in the analyses; retained in the full dataset. |
| IOS_sibs | Sibling relationship closeness (Inclusion of Other in Self) | 1–7 pictorial | child | Which picture best describes your relationship with your sibling? | Handling of children without siblings is unspecified. |
| childrenInHousehold | Number of siblings | integer | parent | How many siblings does your child grow up with? |  |
| statusLadder | Perceived self peer status | 0-7 ladder | child | Here is a picture of a ladder. Imagine the top step on the ladder is for the most liked student in your class. And the bottom step on the ladder is for the least liked student in your class. Where would you place yourself on this ladder? |  |
| autonomy1 | Autonomy support items | 1-5 Likert | child | I often decide for myself what I do. (1 = completely untrue, 5 = completely true) |  |
| autonomy2 | Autonomy support items | 1-5 Likert | child | When I am not allowed to do something, my parents tell me why. (1 = completely untrue, 5 = completely true) |  |
| autonomy3 | Autonomy support items | 1-5 Likert | child | My parents often understand how I feel. (1 = completely untrue, 5 = completely true) |  |
| parentalLeave | Months of parental leave | months | parent | Regarding the child playing with you today, for how many months after birth was at least one parent home with the child full-time? (If both parents stayed home at the same time, count those months only once) |  |
| showHow | Parental scaffolding behavior | 1–4 | parent | I always first show my child how to do something before he/she tries it themselves. (1 = completely untrue, 4 = completely true) |  |
| selfEfficacy | Child perseverance belief | 1–4 | parent | My child believes in themselves and perseveres even when things don’t work out right away. (1 = completely untrue, 4 = completely true) |  |
| IOS_parent | Parent-rated IOS | 1-7 pictorial | parent | Which picture best describes your relationship with your child (with whom you just played this game)? | Same item: IOS_parents in wave 9; IOS_parent in wave 10. Combine by wave when pooling. |
| IOS_child | Child-rated IOS | 1-7 pictorial | child | Which picture best describes your relationship with your parent (you just played this game with)? |  |
| z_resid | Age-adjusted initial estimation error residual | Continuous, standardized | derived |  | Participant mean absolute initial error regressed on age; residual divided by residual sample SD and joined by ppt. |
| s_adj | Social information use (adjustment score) | (secondEstimate-firstEstimate)/(socialInfo-firstEstimate) | derived |  | NA if any required estimate is missing or socialInfo equals firstEstimate. Values outside [0,1] are preserved here and filtered in most analyses. |

## Definition gaps

`siblingsChild` codes 1/2 are undocumented; the variable was not used in analyses. Parent-rated TIPI scores use a 2–14 scale. Equivalent PSQ and IOS column names are identified in the dictionary.
