<?php
/**
 * @file
 * rs_beliana_workbench.features.workbench_moderation_states.inc
 */

/**
 * Implements hook_workbench_moderation_export_states().
 */
function rs_beliana_workbench_workbench_moderation_export_states() {
  $items = array(
    '1_korektura' => array(
      'name' => '1_korektura',
      'label' => '1. korektúra',
      'description' => 'U redaktora/redaktorov na 1. korektúru',
      'weight' => 10,
    ),
    '2_korekt_ra' => array(
      'name' => '2_korekt_ra',
      'label' => '2. korektúra',
      'description' => 'U redaktora/redaktorov na 2. korektúru',
      'weight' => 10,
    ),
    '_ilustr_cia_u_autora' => array(
      'name' => '_ilustr_cia_u_autora',
      'label' => 'Ilustrácia u autora',
      'description' => ' Ilustrácia u autora',
      'weight' => 10,
    ),
    'draft' => array(
      'name' => 'draft',
      'label' => 'Navrhnuté',
      'description' => 'Heslo navrhnuté na zaradenie do B., musí byť odsúhlasené správcom GH',
      'weight' => 0,
    ),
    'ilustracia_na_webe' => array(
      'name' => 'ilustracia_na_webe',
      'label' => 'Ilustrácia na webe',
      'description' => 'Ilustrácie je publikovaná na webe',
      'weight' => 10,
    ),
    'ilustracia_na_zverejnenie' => array(
      'name' => 'ilustracia_na_zverejnenie',
      'label' => 'Ilustrácia na zverejnenie',
      'description' => '',
      'weight' => 10,
    ),
    'ilustracia_u_grafika' => array(
      'name' => 'ilustracia_u_grafika',
      'label' => 'Ilustrácia u grafika',
      'description' => '',
      'weight' => 10,
    ),
    'ilustracia_u_redaktora' => array(
      'name' => 'ilustracia_u_redaktora',
      'label' => 'Ilustrácia u redaktora',
      'description' => '',
      'weight' => 10,
    ),
    'ilustracia_u_vyst_redaktora_5' => array(
      'name' => 'ilustracia_u_vyst_redaktora_5',
      'label' => 'Ilustrácia u výst. redaktora 5',
      'description' => 'Ilustrácia u výstupného redaktora 5',
      'weight' => 10,
    ),
    'importovane' => array(
      'name' => 'importovane',
      'label' => 'Importované',
      'description' => 'Importované heslo (zo súboru)',
      'weight' => -10,
    ),
    'importovane_u_jr2' => array(
      'name' => 'importovane_u_jr2',
      'label' => 'Importované u JR',
      'description' => 'Jazyková redakcia importovaného hesla',
      'weight' => -9,
    ),
    'importovane_u_vr' => array(
      'name' => 'importovane_u_vr',
      'label' => 'Importované u VR',
      'description' => 'Importovane heslo u VR na kontrolu pred zverejnenim',
      'weight' => -8,
    ),
    'importovane_vyradene' => array(
      'name' => 'importovane_vyradene',
      'label' => 'Importované - vyradené',
      'description' => 'Importované heslá, ktoré nebudú zverejneé na webe',
      'weight' => -2,
    ),
    'len_vyplatit' => array(
      'name' => 'len_vyplatit',
      'label' => 'Len vyplatiť',
      'description' => 'Heslo bolo vypracované, ale text sa nepoužije. Treba vyplatiť',
      'weight' => 10,
    ),
    'na_jazykovu_korekturu' => array(
      'name' => 'na_jazykovu_korekturu',
      'label' => 'U jaz. redaktora 1',
      'description' => 'Heslo odoslané na  1. jazykovú korektúru, pracuje s ním jazykový redaktor 1',
      'weight' => 10,
    ),
    'na_opakovane_zverejnenie' => array(
      'name' => 'na_opakovane_zverejnenie',
      'label' => 'Na opakované zverejnenie',
      'description' => 'Na opakované odoslanie zverejneného hesla po úprave na web',
      'weight' => -3,
    ),
    'na_zalomenie' => array(
      'name' => 'na_zalomenie',
      'label' => 'Na zverejnenie/zalomenie',
      'description' => 'Heslo je pripravené pre web alebo tlač',
      'weight' => -7,
    ),
    'na_zverejnenie' => array(
      'name' => 'na_zverejnenie',
      'label' => 'U výst. redaktora 1',
      'description' => 'Heslo odoslané na posúdenie výstupnému redaktorovi 1',
      'weight' => 5,
    ),
    'navrhnute_na_vyradenie' => array(
      'name' => 'navrhnute_na_vyradenie',
      'label' => 'Navrhnuté na zmenu',
      'description' => 'Heslo navrhnuté na vyradenie alebo zmenu názvu al LS',
      'weight' => 1,
    ),
    'needs_review' => array(
      'name' => 'needs_review',
      'label' => 'U redaktora',
      'description' => 'Heslo odoslané na posúdenie redaktorovi, pracuje s ním redaktor',
      'weight' => 4,
    ),
    'nova_ilustracia' => array(
      'name' => 'nova_ilustracia',
      'label' => 'Nová ilustrácia',
      'description' => '',
      'weight' => 10,
    ),
    'pozdr_an_' => array(
      'name' => 'pozdr_an_',
      'label' => 'Pozdržané',
      'description' => 'Heslo na ceste k zverejnieniu, ale dočasne pozdržané ',
      'weight' => -1,
    ),
    'publikovane_na_webe' => array(
      'name' => 'publikovane_na_webe',
      'label' => 'Zverejnené na webe',
      'description' => 'Finálny stav hesla po akcii "Zverejniť na webe"',
      'weight' => -6,
    ),
    'published' => array(
      'name' => 'published',
      'label' => 'published',
      'description' => 'nepoužívané',
      'weight' => 10,
    ),
    'u_autora' => array(
      'name' => 'u_autora',
      'label' => 'U autora',
      'description' => 'Na vypracovanie autorom,  pred odoslaním redaktorovi',
      'weight' => 3,
    ),
    'u_jaz_redaktora_2' => array(
      'name' => 'u_jaz_redaktora_2',
      'label' => 'U jaz. redaktora 2',
      'description' => 'Heslo odoslané na  2. jazykovú korektúru, pracuje s ním jazykový redaktor 2',
      'weight' => 10,
    ),
    'u_konzultanta' => array(
      'name' => 'u_konzultanta',
      'label' => 'U konzultanta',
      'description' => 'heslo u konzultanta',
      'weight' => 10,
    ),
    'u_v_st_redaktora_5' => array(
      'name' => 'u_v_st_redaktora_5',
      'label' => 'U výst. redaktora 5',
      'description' => 'Na spracovanie u výst. redaktora 5',
      'weight' => 9,
    ),
    'u_vyst_redaktora_2' => array(
      'name' => 'u_vyst_redaktora_2',
      'label' => 'U výst. redaktora 2',
      'description' => 'Na spracovanie u výst. redaktora 2',
      'weight' => 6,
    ),
    'u_vyst_redaktora_3' => array(
      'name' => 'u_vyst_redaktora_3',
      'label' => 'U výst. redaktora 3',
      'description' => 'Na spracovanie u výst. redaktora 3',
      'weight' => 7,
    ),
    'u_vyst_redaktora_4' => array(
      'name' => 'u_vyst_redaktora_4',
      'label' => 'U výst. redaktora 4',
      'description' => 'Na spracovanie u výst. redaktora 4',
      'weight' => 8,
    ),
    'ukoncenezluene' => array(
      'name' => 'ukoncenezluene',
      'label' => 'Ukončené/zlúčené',
      'description' => 'Heslo bolo zlúčené s inými heslami, v pôvodnej forme ďalej nepokračuje ',
      'weight' => 10,
    ),
    'vyradene' => array(
      'name' => 'vyradene',
      'label' => 'Vyradené',
      'description' => 'Heslo ďalej neexistuje, z Beliany bolo vyradené',
      'weight' => 10,
    ),
    'zaradene' => array(
      'name' => 'zaradene',
      'label' => 'Zaradené',
      'description' => 'Zaradené do B., môže byť priradené autorovi na vypracovanie',
      'weight' => 2,
    ),
    'zlucene' => array(
      'name' => 'zlucene',
      'label' => 'Zlúčené',
      'description' => 'Heslo vytvorené zlúčením',
      'weight' => 10,
    ),
    'zlucene_odkazy' => array(
      'name' => 'zlucene_odkazy',
      'label' => 'Zlúčené-odkazy',
      'description' => 'Kontrola odkazov na vytvorené zlúčené heslo v iných heslách',
      'weight' => 10,
    ),
    'zverejnene_oprava' => array(
      'name' => 'zverejnene_oprava',
      'label' => 'Zverejnené – oprava',
      'description' => 'Oprava zverejneneho hesla rolou zRedaktor',
      'weight' => -5,
    ),
    'zverejnene_vratene' => array(
      'name' => 'zverejnene_vratene',
      'label' => 'Zverejnené – vrátené',
      'description' => 'Zverejnené heslo vrátené redaktorovi na úpravu',
      'weight' => -4,
    ),
  );
  return $items;
}
