<?php

/**
 * @file
 * Content moderation for Workbench.
 *
 * Based on content_moderation.module by eugenmayer.
 * Base version 1.12.2.17 2010/04/18 11:31:29.
 */

/**
 * Implements hook_menu().
 */
function workbench_moderation_menu() {
  $items = array();

  // Display a node's moderation history
  $items["node/%node/moderation"] = array(
    'title' => 'Moderate',
    'description' => 'Show the content moderation history.',
    'type' => MENU_LOCAL_TASK,
    'page callback' => 'workbench_moderation_node_history_view',
    'page arguments' => array(1),
    'access callback' => '_workbench_moderation_access',
    'access arguments' => array('view history', 1),
    'file' => 'workbench_moderation.node.inc'
  );

  // Unpublishing a live revision.
  $items["node/%node/moderation/%/unpublish"] = array(
    'title' => 'Unpublish revision',
    'description' => 'Unpublish the current live revision.',
    'type' => MENU_CALLBACK,
    'page callback' => 'drupal_get_form',
    'page arguments' => array('workbench_moderation_node_unpublish_form', 1),
    'load arguments' => array(3),
    'access callback' => '_workbench_moderation_access',
    'access arguments' => array('unpublish', 1),
    'file' => 'workbench_moderation.node.inc'
  );

  // Change the moderation state of a node.
  // Used in workbench_moderation_get_moderation_links()
  $items["node/%node/moderation/%/change-state/%"] = array(
    'title' => 'Change moderation state',
    'page callback' => 'workbench_moderation_moderate_callback',
    'page arguments' => array(1, 5),
    'load arguments' => array(3),
    'access callback' => '_workbench_moderation_moderate_access',
    'access arguments' => array(1, 5),
    'type' => MENU_CALLBACK,
  );

  $items['node/%node/moderation/view'] = array(
    'title' => 'Revisions',
    'type' => MENU_DEFAULT_LOCAL_TASK,
    'weight' => -1,
  );

  // View the current revision of a node. Redirects to node/%node if the current revision is
  // published, and to node/%node/draft if the current revision is a draft.
  $items["node/%node/current-revision"] = array(
    'page callback' => 'workbench_moderation_node_current_view',
    'page arguments' => array(1),
    'access arguments' => array('access content'),
    'file' => 'workbench_moderation.node.inc',
  );

  // View the current draft of a node.
  $items["node/%node/draft"] = array(
    'title' => 'View draft',
    'page callback' => 'workbench_moderation_node_view_draft',
    'page arguments' => array(1),
    'access callback' => '_workbench_moderation_access_current_draft',
    'access arguments' => array(1),
    'file' => 'workbench_moderation.node.inc',
    'type' => MENU_LOCAL_TASK,
    'weight' => -9,
  );

  // Module settings.
  $items["admin/config/workbench/moderation"] = array(
    'title' => 'Workbench Moderation',
    'description' => 'Configure content moderation.',
    'page callback' => 'drupal_get_form',
    'page arguments' => array('workbench_moderation_admin_states_form'),
    'access arguments' => array('administer workbench moderation'),
    'file' => 'workbench_moderation.admin.inc',
  );
  $items['admin/config/workbench/moderation/general'] = array(
    'title' => 'States',
    'type' => MENU_DEFAULT_LOCAL_TASK,
    'weight' => -1,
  );
  $items['admin/config/workbench/moderation/transitions'] = array(
    'title' => 'Transitions',
    'type' => MENU_LOCAL_TASK,
    'page callback' => 'drupal_get_form',
    'page arguments' => array('workbench_moderation_admin_transitions_form'),
    'access arguments' => array('administer workbench moderation'),
    'file' => 'workbench_moderation.admin.inc',
  );
  $items['admin/config/workbench/moderation/check-permissions'] = array(
    'title' => 'Check permissions',
    'type' => MENU_LOCAL_TASK,
    'page callback' => 'drupal_get_form',
    'page arguments' => array('workbench_moderation_admin_check_role_form'),
    'access arguments' => array('administer workbench moderation'),
    'file' => 'workbench_moderation.admin.inc',
    'weight' => 10,
  );

  // If the diff module is present, replicate its pages under the moderation tab.
  if (module_exists('diff')) {
    $diff_menu_items  = diff_menu();

    $items['node/%node/moderation/diff'] = array(
      'type' => MENU_LOCAL_TASK,
      'file path' => drupal_get_path('module', 'diff'),
      'title' => 'Compare revisions',
      'page arguments' => array(1),
    );

    $items['node/%node/moderation/diff'] += $diff_menu_items['node/%node/revisions/list'];


    $items['node/%node/moderation/diff/list'] = array(
      'title' => 'Compare revisions',
      'type' => MENU_DEFAULT_LOCAL_TASK,
      'weight' => -1,
    );

    $items['node/%node/moderation/diff/view'] = array(
      'page arguments' => array(1, 5, 6),
      'tab_parent' => 'node/%/moderation/diff/list',
      'file path' => drupal_get_path('module', 'diff'),
    );

    $items['node/%node/moderation/diff/view'] += $diff_menu_items['node/%node/revisions/view'];
  }

  return $items;
}


/**
 * Implements hook_form_FORM_ID_alter.
 */
function workbench_moderation_form_diff_node_revisions_alter(&$form, &$form_state, $form_id) {

  // If this form is appearing under moderation then add a submit function
  // that will keep the user in the moderation tab.
  if (arg(2) == 'moderation') {
    $form['#submit'][] = 'workbench_moderation_diff_node_revisions_submit';
  }
}

/**
 * Redirects the the diff_node_revisions form when the user is under the moderation tab.
 */
function workbench_moderation_diff_node_revisions_submit($form, &$form_state) {

  // the ids are ordered so the old revision is always on the left
  $old_vid = min($form_state['values']['old'], $form_state['values']['new']);
  $new_vid = max($form_state['values']['old'], $form_state['values']['new']);
  $form_state['redirect'] =  'node/'. $form_state['values']['nid'] .'/moderation/diff/view/'. $old_vid .'/'. $new_vid;
}

/**
 * Implements hook_menu_alter().
 */
function workbench_moderation_menu_alter(&$items) {
  // Hijack the node/X/edit page to ensure that the right revision (most current) is displayed.
  $items['node/%node/edit']['page callback'] = 'workbench_moderation_node_edit_page_override';

  // Override the node edit menu item title.
  $items['node/%node/edit']['title callback'] = 'workbench_moderation_edit_tab_title';
  $items['node/%node/edit']['title arguments'] = array(1);

  // Override the node view menu item title.
  $items['node/%node/view']['title callback'] = 'workbench_moderation_view_tab_title';
  $items['node/%node/view']['title arguments'] = array(1);

  // Redirect node/%node/revisions
  $items['node/%node/revisions']['page callback'] = 'workbench_moderation_node_revisions_redirect';
  $items['node/%node/revisions']['page arguments'] = array(1);

  // Override the node revision view callback.
 $items['node/%node/revisions/%/view']['page callback'] = 'workbench_moderation_node_view_revision';
 $items['node/%node/revisions/%/view']['file path'] = drupal_get_path('module', 'workbench_moderation');
 $items['node/%node/revisions/%/view']['file'] = 'workbench_moderation.node.inc';


  // For revert and delete operations, use our own access check.
  $items['node/%node/revisions/%/revert']['access callback'] = '_workbench_moderation_revision_access';
  $items['node/%node/revisions/%/delete']['access callback'] = '_workbench_moderation_revision_access';

  // Provide a container administration menu item, if one doesn't already exist.
  if (!isset($items['admin/config/workbench'])) {
    $items['admin/config/workbench'] = array(
      'title' => 'Workbench',
      'description' => 'Workbench',
      'page callback' => 'system_admin_menu_block_page',
      'access arguments' => array('administer site configuration'),
      'position' => 'right',
      'file' => 'system.admin.inc',
      'file path' => drupal_get_path('module', 'system'),
    );
  }
}

/**
 * Redirects 'node/%node/revisions' to node/%node/moderation
 *
 * workbench_moderation_menu_alter() changes the page callback
 * for 'node/%node/revisions' to this function
 *
 * @param $node
 *   The node being acted upon.
 */
function workbench_moderation_node_revisions_redirect($node) {
  // Redirect nodes subject to moderation.
  if (workbench_moderation_node_moderated($node) === TRUE) {
    drupal_goto('node/' . $node->nid . '/moderation');
  }
  // Return the normal node revisions page for unmoderated types.
  else {

    if (module_exists('diff')) {
      return diff_diffs_overview($node);
    }
    else {
      return node_revision_overview($node);
    }
  }
}

/**
 * Implements hook_menu_local_tasks_alter().
 *
 * Hide the node revisions tab conditionally.
 *
 * Check if the node type is subject to moderation. If so, unset the revision
 * tab. This step is necessary because hook_menu_alter cannot change the menu
 * item type on a node type by node type basis for node/%node/revision.
 *
 * Additionally, workbench_menu_alter() is used to change the page callback
 * for node/%node/revisions so that this URL redirects to node/%node/moderation
 * for node types subject to moderation.
 */
function workbench_moderation_menu_local_tasks_alter(&$data, $router_item, $root_path) {
  // Do we need to bother doing anything?
  if (empty($data['tabs'][0]['output'])) {
    return;
  }

  // Check the path.
  $arg = arg(0, $root_path);
  $arg1 = arg(1, $root_path);
  if ($arg != 'node' || $arg1 != '%') {
    return;
  }

  // Get the node for the current menu router.
  if ($node = menu_get_object()) {
    // Here is the reason this hook implementation exists:
    // If this is a node that gets moderated, don't show 'node/%/revisions'
    if (workbench_moderation_node_moderated($node) === TRUE) {
      foreach ($data['tabs'][0]['output'] as $key => $value) {
        if (!empty($value['#link']['path']) && $value['#link']['path'] == 'node/%/revisions') {
          unset($data['tabs'][0]['output'][$key]);
          break;
        }
      }
    }
  }
}

/**
 * Change the name of the node edit tab, conditionally.
 *
 * - Don't change the title if the content is not under moderation.
 *
 * - If a piece of content has a published revision and the published revision
 *   is also the current moderation revision, the "Edit" tab should be titled
 *   "Create draft".
 *
 * - If a piece of content has a published revision and the current moderation
 *   revision is a newer, or if the content has no published revision, the
 *   "Edit" tab should be titled "Edit draft".
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   The title for the tab.
 */
function workbench_moderation_edit_tab_title($node) {
  // Use the normal tab title if the node is not under moderation.
  if (!workbench_moderation_node_moderated($node)) {
    return t('Edit');
  }

  // Is the latest draft published?
  $state = $node->workbench_moderation;
  if (!empty($state['published']) && $state['published']->vid == $state['current']->vid) {
    return t('New draft');
  }

  // The latest draft is not published.
  return t('Edit draft');
}

/**
 * Change the name of the node view tab, conditionally.
 *
 * - Don't change the title if the content is not under moderation.
 *
 * - If a piece of content has a published revision, the "View" tab should be
 *   titled "View published".
 *
 * - Otherwise, it should be titled "View draft".
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   The title for the tab.
 */
function workbench_moderation_view_tab_title($node) {
  // Use the normal tab title if the node is not under moderation.
  if (!workbench_moderation_node_moderated($node)) {
    return t('View');
  }

  // Is there a published revision?
  $state = $node->workbench_moderation;
  if (!empty($state['published'])) {
    return t('View published');
  }
  return t('View draft');
}


/**
 * Implements hook_admin_paths().
 */
function workbench_moderation_admin_paths() {
  if (variable_get('node_admin_theme')) {
    $paths = array(
      'node/*/moderation' => TRUE,
      'node/*/moderation/*/unpublish' => TRUE,
      'node/*/moderation/*/change-state/*' => TRUE,
      'node/*/moderation/view' => TRUE,
      'node/*/moderation/diff' => TRUE,
      'node/*/moderation/diff/list' => TRUE,
      'node/*/moderation/diff/view' => TRUE,
      'node/*/moderation/diff/view/*/*' => TRUE,
    );
    return $paths;
  }
}

/**
 * Implements hook_theme().
 */
function workbench_moderation_theme() {
  return array(
    'workbench_moderation_admin_states_form' => array(
      'file' => 'workbench_moderation.admin.inc',
      'render element' => 'form',
    ),
    'workbench_moderation_admin_transitions_form' => array(
      'file' => 'workbench_moderation.admin.inc',
      'render element' => 'form',
    ),
  );
}

/**
 * Implements hook_permission().
 *
 * Provides permissions for each state to state change.
 */
function workbench_moderation_permission() {
  $permissions = array();
  $permissions['view all unpublished content'] = array(
    'title' => t('View all unpublished content'),
  );
  $permissions['administer workbench moderation'] = array(
    'title' => t('Administer Workbench Moderation'),
  );
  $permissions['bypass workbench moderation'] = array(
    'title' => t('Bypass moderation restrictions'),
    'restrict access' => TRUE,
  );
  $permissions['view moderation history'] = array(
    'title' => t('View moderation history'),
  );
  $permissions['view moderation messages'] = array(
    'title' => t('View the moderation messages on a node')
  );
  $permissions['use workbench_moderation my drafts tab'] = array(
    'title' => t('Use "My drafts" workbench tab')
  );
  $permissions['use workbench_moderation needs review tab'] = array(
    'title' => t('Use "Needs review" workbench tab')
  );

  // Per-node-type, per-transition permissions. Used by workbench_moderation_state_allowed().
  $node_types = workbench_moderation_moderate_node_types();
  $transitions = workbench_moderation_transitions();

  foreach ($transitions as $transition) {
    $from_state = $transition->from_name;
    $to_state = $transition->to_name;

    // Always set a permission to perform all moderation states.
    $permissions["moderate content from $from_state to $to_state"] = array(
      'title' => t('Moderate all content from %from_state to %to_state', array('%from_state' => workbench_moderation_state_label($from_state), '%to_state' => workbench_moderation_state_label($to_state))),
    );
    // Per-node type permissions are very complex, and should only be used if
    // absolutely needed. For right now, this is hardcoded to OFF. To enable it,
    // Add this line to settings.php and then reset permissions.
    //   $conf['workbench_moderation_per_node_type'] = TRUE;
    if (variable_get('workbench_moderation_per_node_type', FALSE)) {
      foreach ($node_types as $node_type) {
        $permissions["moderate $node_type state from $from_state to $to_state"] = array(
          'title' => t('Moderate %node_type state from %from_state to %to_state', array('%node_type' => node_type_get_name($node_type), '%from_state' => workbench_moderation_state_label($from_state), '%to_state' => workbench_moderation_state_label($to_state))),
        );
      }
    }
  }
  return $permissions;
}

/**
 * Implements hook_node_access().
 *
 * Allows users with the 'view all unpublished content' permission to do so.
 */
function workbench_moderation_node_access($node, $op, $account) {
  if ($op == 'view' && !$node->status && user_access('view all unpublished content', $account)) {
    return NODE_ACCESS_ALLOW;
  }
  return NODE_ACCESS_IGNORE;
}

/**
 * Implements hook_node_grants().
 *
 * We associated role IDs with the 'view all unpublished content' permission with
 * the workbench_moderation realm in the node_access table. Here, we return the
 * role ID values associated with the user.
 */
function workbench_moderation_node_grants($user, $op) {
  $grants['workbench_moderation'] = array_keys($user->roles);
  return $grants;
}

/**
 * Implements hook_node_access_records().
 *
 * This function supplies the workbench moderation grants for unpublished
 * content. workbench_moderation adds the 'view all unpublished content'
 * permission so it captures and returns the role IDs which include that
 * permission.
 */
function workbench_moderation_node_access_records($node) {
  if ($node->status) {
    // It's published, default handling is okay.
    return;
  }
  $result = db_query("SELECT rid FROM {role_permission} WHERE permission = 'view all unpublished content'");
  foreach ($result as $grant) {
    $grants[] = array(
      'realm' => 'workbench_moderation',
      'gid' => $grant->rid,
      'grant_view' => 1,
      'grant_update' => 0,
      'grant_delete' => 0,
      'priority' => 0,
    );
  }
  return !empty($grants) ? $grants : array();
}

/**
 * Custom access handler for node operations.
 *
 * @param $op
 *   The operation being requested.
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   Boolean TRUE or FALSE.
 */
function _workbench_moderation_access($op, $node) {
  global $user;

  // If we do not control this node type, deny access.
  if (workbench_moderation_node_type_moderated($node->type) === FALSE) {
    return FALSE;
  }

  $access = TRUE;

  // The user must be able to view the moderation history.
  $access &= user_access('view moderation history');

  // The user must be able to edit this node.
  $access &= node_access('update', $node);

  if ($op == 'unpublish') {
    // workbench_moderation_states_next() checks transition permissions.
    $next_states = workbench_moderation_states_next(workbench_moderation_state_published(), $user, $node);
    $access &= !empty($next_states);
  }

  // Allow other modules to change our rule set.
  drupal_alter('workbench_moderation_access', $access, $op, $node);

  return $access;
}

/**
 * Wrapper for the 'revert' and 'delete' operations of _node_revision_access().
 *
 * Drupal core's "current revision" of a node is the version in {node}; for
 * Workbench Moderation, latest revision in {node_revision} is the current
 * revision. For nodes with a published revision, Workbench Moderation keeps
 * that revision in {node}, whether or not it is the current revision.
 */
function _workbench_moderation_revision_access($node, $op) {
  // Normal behavior for unmoderated nodes.
  if (!workbench_moderation_node_moderated($node)) {
    return _node_revision_access($node, $op);
  }

  // Prevent reverting to (ie, update) the current revision.
  if ($node->workbench_moderation['current']->vid == $node->workbench_moderation['my_revision']->vid) {
    if ($op == 'update') {
      return FALSE;
    }
  }
  // Prevent deleting the current revision, if there is no separate published
  // revision. This also prevents deleting the current revision if it is the
  // only revision, and its unpublished.
  if ($node->workbench_moderation['current']->vid == $node->workbench_moderation['my_revision']->vid) {
    if ($op == 'delete' && !isset($node->workbench_moderation['published'])) {
      // In theory, deleting the one and only revision of a node could be
      // allowed but we'd need to add special logic that actually deletes
      // the node, not just the revision.
      return FALSE;
    }
  }
  // Prevent deleting a published revision.
  if (isset($node->workbench_moderation['published']) && $node->workbench_moderation['published']->vid == $node->workbench_moderation['my_revision']->vid) {
    if ($op == 'delete') {
      // In theory, deleting a published revision could be allowed but we'd
      // need to solve the problem of determining what to do if you delete the
      // published revision, e.g., what database tables and fields would need
      // to be cascaded for such a change.
      return FALSE;
    }
  }

  // Temporarily give the node an impossible revision.
  // _node_revision_access() keeps access check results in a static variable
  // indexed by revision only, not by op. Thus, subsequent checks on the same
  // vid for different ops yield the same result, regardless of permissions.
  // Setting a fake vid here allows us to store different static results per op.
  $tmp = $node->vid;
  switch ($op) {
    case 'update':
      $node->vid = -1;
      break;
    case 'delete':
      $node->vid = -2;
      break;
  }

  // Check access.
  $access = _node_revision_access($node, $op);

  // Restore the original revision id.
  $node->vid = $tmp;
  return $access;
}

/**
 * Checks if a user may make a particular transition on a node.
 *
 * @param $node
 *   The node being acted upon.
 * @param $state
 *   The new moderation state.
 *
 * @return
 *   Booelan TRUE or FALSE.
 */
function _workbench_moderation_moderate_access($node, $state) {
  global $user;

  $my_revision = $node->workbench_moderation['my_revision'];
  $next_states = workbench_moderation_states_next($my_revision->state, $user, $node);
  $access = node_access('update', $node, $user)       // the user can edit the node
          && $my_revision->is_current                 // this is the current revision (no branching the revision history)
          && (!empty($next_states))                   // there are next states the user may transition to
          && isset($next_states[$state]);             // this state is in the available next states

  // Allow other modules to change our rule set.
  $op = 'moderate';
  drupal_alter('workbench_moderation_access', $access, $op, $node);

  return $access;
}

/**
 * Checks if the user can view the current node revision.
 *
 * This is the access callback for node/%node/draft as defined in
 * workbench_moderation_menu().
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   Booelan TRUE or FALSE.
 */
function _workbench_moderation_access_current_draft($node) {

  // This tab should only appear for nodes under moderation
  if (!workbench_moderation_node_moderated($node)) {
    return FALSE;
  }

  $state = $node->workbench_moderation;
  return (_workbench_moderation_access('view revisions', $node)
      && !empty($state['published'])
      && $state['published']->vid != $state['current']->vid);
}

/**
 * Implements hook_help().
 */
function workbench_moderation_help($path, $arg) {
  switch ($path) {
    case 'admin/help#workbench_moderation':
      return '<p>' . t("Enables you to control node display with a moderation workflow. You can have a 'Live revision' for all visitors and pending revisions which need to be approved to become the new 'Live revision.'") . '</p>';

    case 'admin/config/workbench/moderation':
      return '<p>' . t("These are the states through which a node passes in order to become published. By default, the Workbench Moderation module provides the states 'Draft,' 'Needs review,' and 'Published'. On this screen you may create, delete and re-order states. Additional states might include 'Legal review,' 'PR review', or any or state your site may need.") . '</p>';

    case 'admin/config/workbench/moderation/transitions':
      return '<p>' . t('The Workbench Moderation module keeps track of when a node moves from one state to another. By default, nodes begin in the %draft state and end in the %published state. The transitions on this page control how nodes move from state to state. <a href="@permissions">Permission to perform these transitions is controlled on a role-by-role basis</a>.', array('%draft' => workbench_moderation_state_label(workbench_moderation_state_none()), '%published' => workbench_moderation_state_label(workbench_moderation_state_published()), '@permissions' => url('admin/people/permissions', array('fragment' => 'module-workbench_moderation')))) . '</p>';

    case 'admin/config/workbench/moderation/check-permissions':
      return '<p>' . t("In order to participate in the moderation process, Drupal users must be granted several node- and moderation- related permissions. This page can help check whether roles have the correct permissions to author, edit, moderate, and publish moderated content.") . '</p>';
  }
}

/**
 * Implements hook_features_api().
 */
function workbench_moderation_features_api() {
  return array(
    'workbench_moderation_states' => array(
      'name' => t('Workbench States'),
      'default_hook' => 'workbench_moderation_export_states',
      'feature_source' => TRUE,
      'default_file' => FEATURES_DEFAULTS_INCLUDED,
      'file' => drupal_get_path('module', 'workbench_moderation') .'/workbench_moderation.features.inc',
    ),
    'workbench_moderation_transitions' => array(
      'name' => t('Workbench Transitions'),
      'default_hook' => 'workbench_moderation_export_transitions',
      'feature_source' => TRUE,
      'default_file' => FEATURES_DEFAULTS_INCLUDED,
      'file' => drupal_get_path('module', 'workbench_moderation') .'/workbench_moderation.features.inc',
    ),
  );
}

/**
 * Implements hook_views_api().
 */
function workbench_moderation_views_api() {
  return array('api' => 2.0);
}

/**
 * Implements hook_views_default_views().
 */
function workbench_moderation_views_default_views() {
  $module = 'workbench_moderation';
  $directory = 'views';
  $extension = 'view.inc';
  $name = 'view';

  // From workbench_load_all_exports().
  $return = array();
  // Find all the files in the directory with the correct extension.
  $files = file_scan_directory(drupal_get_path('module', $module) . "/$directory", "/.$extension/");
  foreach ($files as $path => $file) {
    require $path;
    if (isset($$name)) {
      $return[$$name->name] = $$name;
    }
  }

  return $return;
}


/**
 * Implements hook_node_presave().
 *
 * Ensure that a node in moderation has the proper publication status.
 * We set $node->status = 0 (unpublished) if this is a new node which has not
 * been marked as published, or if the node has no published revision.
 */
function workbench_moderation_node_presave($node) {
  global $user;
  if (isset($node->workbench_moderation_state_new)) {
    // If the new moderation state is published, set the node status to
    // published.
    if ($node->workbench_moderation_state_new == workbench_moderation_state_published()) {
      $node->status = 1;
    }
    else {
      $node->status = 0;
    }
  }

  // Preserve the changed timestamp of the revision when updating live revision.
  if (!empty($node->workbench_moderation['updating_live_revision'])) {
    $node->timestamp = $node->workbench_moderation['my_revision']->stamp;
    $node->changed = $node->workbench_moderation['my_revision']->stamp;
  }
}

/**
 * Implements hook_node_insert().
 *
 * Wrapper call to the update hook.
 */
function workbench_moderation_node_insert($node) {
  workbench_moderation_node_update($node);
}

/**
 * Implements hook_node_update().
 *
 * Handles the submit of the node form moderation information
 */
function workbench_moderation_node_update($node) {
  global $user;

  // Don't proceed if moderation is not enabled on this content, or if
  // we're replacing an already-published revision.
  if (!workbench_moderation_node_moderated($node) ||
      !empty($node->workbench_moderation['updating_live_revision'])) {
    return;
  }

  // Set moderation state values.
  if (!isset($node->workbench_moderation_state_current)) {
    $node->workbench_moderation_state_current = !empty($node->original->workbench_moderation['current']->state) ? $node->original->workbench_moderation['current']->state : workbench_moderation_state_none();
  }
  if (!isset($node->workbench_moderation_state_new)) {
    // Moving from published to unpublished.
    if ($node->status == NODE_NOT_PUBLISHED && isset($node->original->status) && $node->original->status == NODE_PUBLISHED) {
      // @todo Currently we cannot set the state correctly if the default state
      //   is "Published".
      // @see https://www.drupal.org/node/1436260
      $node->workbench_moderation_state_new = variable_get('workbench_moderation_default_state_' . $node->type, workbench_moderation_state_none());
    }
    // Moving from unpublished to published.
    elseif ($node->status == NODE_PUBLISHED && isset($node->original->status) && $node->original->status == NODE_NOT_PUBLISHED) {
      $node->workbench_moderation_state_new = workbench_moderation_state_published();
    }
    else {
      if (!empty($node->original->workbench_moderation['current']->state)) {
        $node->workbench_moderation_state_new = $node->original->workbench_moderation['current']->state;
      }
      else {
        $node->workbench_moderation_state_new = variable_get('workbench_moderation_default_state_' . $node->type, workbench_moderation_state_none());
      }
    }
  }

  // If this is a new node, give it some information about 'my revision'.
  if (!isset($node->workbench_moderation)) {
    $node->workbench_moderation = array();
    $node->workbench_moderation['my_revision'] = $node->workbench_moderation['current'] = (object) array(
      'from_state' => workbench_moderation_state_none(),
      'state' => workbench_moderation_state_none(),
      'nid' => $node->nid,
      'vid' => $node->vid,
      'uid' => $user->uid,
      'is_current' => TRUE,
      'published' => FALSE,
      'stamp' => $node->changed,
    );
  }

  // Apply moderation changes if this is a new revision or if the moderation
  // state has changed.
  if (!empty($node->revision) || $node->workbench_moderation_state_current != $node->workbench_moderation_state_new) {
    // Update attached fields.
    field_attach_update('node', $node);
    // Moderate the node.
    workbench_moderation_moderate($node, $node->workbench_moderation_state_new);
  }

  return;
}

/**
 * Implements hook_node_load().
 *
 * Load moderation history and status on a node.
 */
function workbench_moderation_node_load($nodes, $types) {
  foreach ($nodes as $node) {
    // Add the node history
    workbench_moderation_node_data($node);
  }
}

/**
 * Implements hook_node_view().
 *
 * Display messages about the node's moderation state.
 */
function workbench_moderation_node_view($node, $view_mode = 'full') {
  // Show moderation state messages if we're on a node page.
  if (node_is_page($node) && $view_mode == 'full' && empty($node->in_preview)) {
    workbench_moderation_messages('view', $node);
  }
}

/**
 * Implements hook_node_delete().
 */
function workbench_moderation_node_delete($node) {
  // Delete node history when it is deleted.
  db_delete('workbench_moderation_node_history')
    ->condition('nid', $node->nid)
    ->execute();
}

/**
 * Implements hook_form_FORM_ID_alter().
 *
 * Add moderation rules to node types.
 */
function workbench_moderation_form_node_type_form_alter(&$form, $form_state) {
  // Get a list of moderation states.
  $options = workbench_moderation_state_labels();

  // Disable the 'revision' checkbox when the 'moderation' checkbox is checked, so that moderation
  // can not be enabled unless revisions are enabled.
  $form['workflow']['node_options']['revision']['#states'] = array(
    'disabled' => array(':input[name="node_options[moderation]"]' => array('checked' => TRUE)),
  );

  // Disable the 'moderation' checkbox when the 'revision' checkbox is not checked, so that
  // revisions can not be turned off without also turning off moderation.
  $form['workflow']['node_options']['#options']['moderation'] = t('Enable moderation of revisions');
  $form['workflow']['node_options']['moderation']['#description'] = t('Revisions must be enabled in order to use moderation.');
  $form['workflow']['node_options']['moderation']['#states'] = array(
    'disabled' => array(':input[name="node_options[revision]"]' => array('checked' => FALSE)),
  );

  // This select element is hidden when moderation is not enabled.
  $form['workflow']['workbench_moderation_default_state'] = array(
    '#title' => t('Default moderation state'),
    '#type' => 'select',
    '#options' => $options,
    '#default_value' => variable_get('workbench_moderation_default_state_' . $form['#node_type']->type),
    '#description' => t('Set the default moderation state for this content type. Users with additional moderation permissions will be able to set the moderation state when creating or editing nodes.'),
    '#states' => array(
      'visible' => array(':input[name="node_options[moderation]"]' => array('checked' => TRUE)),
    ),
  );
  $form['#validate'][] = 'workbench_moderation_node_type_form_validate';
}

/**
 * Validate the content type form.
 */
function workbench_moderation_node_type_form_validate($from, &$form_state) {
  // Ensure that revisions are enabled if moderation is.
  if ($form_state['values']['node_options']['moderation']) {
    $form_state['values']['node_options']['status'] = 0;
    $form_state['values']['node_options']['revision'] = 1;
  }
}

/**
 * Implements hook_form_BASE_FORM_ID_alter().
 *
 * Forcing new reversion and publishing.
 */
function workbench_moderation_form_node_form_alter(&$form, $form_state) {
  global $user;

  // This must be a node form and a node that has moderation enabled.
  // Extended to include moderation check on the individual node.
  if (!workbench_moderation_node_moderated($form['#node'])) {
    return;
  }

  // Set a moderation state even if there is not one defined
  if (isset($form['#node']->workbench_moderation['current']->state)) {
    $moderation_state = $form['#node']->workbench_moderation['current']->state;
  }
  else {
    $moderation_state = workbench_moderation_state_none();
  }

  // Store the current moderation state
  $form['workbench_moderation_state_current'] = array(
    '#type' => 'value',
    '#value' => $moderation_state
  );

  // We have a use case where a published node is being edited. This will always
  // revert back to the original node status.
  if ($moderation_state == workbench_moderation_state_published()) {
    $moderation_state = workbench_moderation_state_none();
  }

  // Get all the states *this* user can access. If there aren't any, this user
  // can not change the moderation state.
  if ($states = workbench_moderation_states_next($moderation_state, $user, $form['#node'])) {
    $states[$moderation_state] = t('@state (Current)', array('@state' => workbench_moderation_state_label($moderation_state)));
    $states_sorted = array();
    foreach (array_keys(workbench_moderation_states()) as $state) {
      if (array_key_exists($state, $states)) {
        $states_sorted[$state] = $states[$state];
      }
    }
    $states = $states_sorted;

    $form['revision_information']['workbench_moderation_state_new'] = array(
      '#title' => t('Moderation state'),
      '#type' => 'select',
      '#options' => $states,
      '#description' => t('Set the moderation state for this content.'),
      '#access' => $states ? TRUE: FALSE,
    );

    // If the user has access to the pre-set default state, make it the default
    // here.  Otherwise, don't set a default in this case.
    // MSMS Make current moderation state the default state, so that the state is not changed unintentionally
    // orig $default_state = variable_get('workbench_moderation_default_state_' . $form['type']['#value']);
    $default_state = $moderation_state;

    if ($default_state && array_key_exists($default_state, $states)) {
      $form['revision_information']['workbench_moderation_state_new']['#default_value'] = $default_state;
    }
    else {
      $form['revision_information']['workbench_moderation_state_new']['#default_value'] = workbench_moderation_state_none();
    }
  }
  else {
    // Store the current moderation state
    $form['workbench_moderation_state_new'] = array(
      '#type' => 'value',
      '#value' => $moderation_state
    );
  }

  // Always create new revisions for nodes that are moderated
  $form['revision_information']['revision'] = array(
    '#type' => 'value',
    '#value' => TRUE,
  );

  // Set a default revision log message.
  $logged_name = (user_is_anonymous() ? variable_get('anonymous', t('Anonymous')) : format_username($user));
  if (!empty($form['#node']->nid)) {
    $form['revision_information']['log']['#default_value'] = t('Edited by !user.', array('!user' => $logged_name));
  }
  else {
    $form['revision_information']['log']['#default_value'] = t('Created by !user.', array('!user' => $logged_name));
  }

  // Move the revision log into the publishing options to make things pretty.
  if ($form['options']['#access']) {
    $form['options']['log'] = $form['revision_information']['log'];
    $form['options']['log']['#title'] = t('Moderation notes');
    $form['options']['workbench_moderation_state_new'] = isset($form['revision_information']['workbench_moderation_state_new']) ? $form['revision_information']['workbench_moderation_state_new'] : '';

    // Unset the old placement of the Revision log.
    unset($form['revision_information']['log']);
    unset($form['revision_information']['workbench_moderation_state_new']);

    // The revision information section should now be empty.
    $form['revision_information']['#access'] = FALSE;
  }

  // Setup the JS for the vertical tabs summary. The heavy weight allows this
  // script to replace the default node summary callbacks that get registered by
  // "lighter" scripts.
  // Note: Form API '#attached' does not allow to set a weight.
  drupal_add_js(drupal_get_path('module', 'workbench_moderation') . '/js/workbench_moderation.js', array('weight' => 90));

  // Users can not choose to publish content; content can only be published by
  // setting the content's moderation state to "Published".
  $form['options']['status']['#access'] = FALSE;
  $form['actions']['submit']['#submit'][] = 'workbench_moderation_node_form_submit';
  workbench_moderation_messages('edit', $form['#node']);
}

/**
 * Redirect to the current revision of a node after editing.
 */
function workbench_moderation_node_form_submit($form, &$form_state) {
  $form_state['redirect'] = array('node/' . $form_state['node']->nid . '/current-revision');
}

/**
 * Overrides the node/%/edit page to ensure the proper revision is shown.
 *
 * @param $node
 *   The node being acted upon.
 * @return
 *   A node editing form.
 */
function workbench_moderation_node_edit_page_override($node) {
  // Check to see if this is an existing node
  if (isset($node->nid)) {
    if (workbench_moderation_node_type_moderated($node->type)) {
      // Load the node moderation data
      workbench_moderation_node_data($node);
      // We ONLY edit the current revision
      $node = workbench_moderation_node_current_load($node);
    }
  }
  // Ensure we have the editing code.
  module_load_include('inc', 'node', 'node.pages');
  return node_page_edit($node);
}

/**
 * Returns the key which represents the live revision.
 *
 * @TODO: make this configurable.
 */
function workbench_moderation_state_published() {
  return 'published';
}

/**
 * Returns the key which represents the neutral non moderated revision.
 *
 * @TODO: make this configurable.
 */
function workbench_moderation_state_none() {
  return 'draft';
}

/**
 * Determines if this content type is set to be moderated
 *
 * @param $type
 *   String, content type name
 *
 * @return boolean
 */
function workbench_moderation_node_type_moderated($type) {
  // Is this content even in moderatation?
  $options = variable_get("node_options_$type", array());
  if (in_array('revision', $options) && in_array('moderation', $options)) {
    return TRUE;
  }
  return FALSE;
}

/**
 * Determines if this content is set to be moderated.
 *
 * @param obj $node
 *   Node object
 *
 * @return boolean
 */
function workbench_moderation_node_moderated($node) {
  // Is this content moderated? (individual node check, for extension purposes).
  $access = workbench_moderation_node_type_moderated($node->type);
  drupal_alter('workbench_moderation_node_moderated', $access, $node);
  return $access;
}

/**
 * Lists content types that are moderated
 */
function workbench_moderation_moderate_node_types() {
  $types = node_type_get_types();
  $result = array();
  foreach ($types as $type) {
    // Is this content even in moderatation?
    if (workbench_moderation_node_type_moderated($type->type)) {
      $result[] = $type->type;
    }
  }
  return $result;
}

/**
 * Checks if a user may change the state of a node.
 *
 * This check is based on transition and node type. Users
 * with the 'bypass workbench moderation' permission may make any state
 * transition.
 *
 * @see workbench_moderation_permission()
 *
 * Note that we do not use content-type specific moderation by default. To
 * enable that, see the instructions in workbench_moderation_permission().
 *
 * @param $account
 *   The user account being checked.
 * @param $from_state
 *   The original moderation state.
 * @param $to_state
 *   The new moderation state.
 *
 * @return
 *   Bollean TRUE or FALSE.
 */
function workbench_moderation_state_allowed($account, $from_state, $to_state, $node_type) {
  // Allow super-users to moderate all content.
  if (user_access("bypass workbench moderation", $account)) {
    return TRUE;
  }

  // Can this user moderate all content for this transition?
  if (user_access("moderate content from $from_state to $to_state", $account)) {
    return TRUE;
  }

  // Are we using complex node type rules for this transition?
  if (variable_get('workbench_moderation_per_node_type', FALSE) && user_access("moderate $node_type state from $from_state to $to_state", $account)) {
    return TRUE;
  }

  // Default return.
  return FALSE;
}

/**
 * Adds current and live revision data to a node.
 *
 * @param $node
 *   The node being acted upon.
 */
function workbench_moderation_node_data($node) {
  // Make sure that this node type is moderated.
  if (!workbench_moderation_node_type_moderated($node->type)) {
    return;
  }

  // Path module is stupid and doesn't load its data in node_load.
  if (module_exists('path') && isset($node->nid)) {
    $path = array();
    $conditions = array('source' => 'node/' . $node->nid);
    $langcode = entity_language('node', $node);
    if ($langcode != LANGUAGE_NONE) {
      $conditions['language'] = $langcode;
    }

    $path = path_load($conditions);
    if ($path === FALSE) {
      $path = array();
    }
    if (isset($node->path)) {
      $path += $node->path;
    }
    $path += array(
      'pid' => NULL,
      'source' => 'node/' . $node->nid,
      'alias' => '',
      'language' => isset($node->language) ? $node->language : LANGUAGE_NONE,
    );

    $node->path = $path;
  }

  // Build a default 'current' moderation record. Nodes will lack a
  // workbench_moderation record if moderation was not enabled for their node
  // type when they were created. In that case, assume the live node is at the
  // current revision.
  $defaults = array(
    'hid' => NULL,
    'nid' => $node->nid,
    'vid' => $node->vid,
    'from_state' => workbench_moderation_state_none(),
    'state' => ($node->status ? workbench_moderation_state_published() : workbench_moderation_state_none()),
    'uid' => $node->uid,
    'stamp' => $node->changed,
    'published' => $node->status,
    'is_current' => 1,
  );

  // We'll store moderation state information in an array on the node.
  $node->workbench_moderation = array();

  // Fetch the most recent revision from the {node_revision} table. This is the
  // current revision ("head").
  $query = db_select('node_revision', 'r');
  $query->addJoin('LEFT OUTER', 'workbench_moderation_node_history', 'm', 'r.vid = %alias.vid');
  $query->condition('r.nid', $node->nid)
    ->orderBy('r.vid', 'DESC')
    ->orderBy('m.hid', 'DESC')
    ->fields('m')
    ->fields('r', array('title', 'timestamp'));
  $current = $query->execute()->fetchObject();

  if (!$current) {
    $current = (object) $defaults;
  }
  else {
    // Fill in any defaults that are missing from the database record. We need
    // to maintain false-y values except for NULL, so array_filter() +
    // array_merge() wouldn't work here.
    foreach (array_keys($defaults) as $key) {
      if (is_null($current->$key)) {
        $current->$key = $defaults[$key];
      }
    }
  }

  $current->is_current = 1;
  $node->workbench_moderation['current'] = $current;

  // Fetch the published revision. There may not be a workbench_moderation
  // record for some nodes, but in those cases if the node is published,
  // $current->published will be TRUE.
  if ($current->published) {
    $published = $current;
  }
  else {
    // Fetch the most recent published revision.
    $query = db_select('node', 'n');
    $query->addJoin('INNER', 'node_revision', 'r', 'n.vid = r.vid');
    $query->addJoin('LEFT OUTER', 'workbench_moderation_node_history', 'm', 'r.vid = m.vid');
    $query->condition('n.nid', $node->nid)
      ->condition('n.status', 1)
      ->orderBy('m.hid', 'DESC')
      ->fields('r', array('nid', 'vid', 'title', 'timestamp'))
      ->fields('m');
    $published = $query->execute()->fetchObject();
  }
  // If we have a published copy, add that to the array.
  if ($published) {
    $published->state = workbench_moderation_state_published();
    $node->workbench_moderation['published'] = $published;
  }

  // Fetch the workbench_moderation record for this node object's revision. If
  // it is either the current or published revision of the node, that data will
  // be used.
  if ($node->vid == $current->vid) {
    $my_revision = $current;
  }
  elseif ($published && $node->vid == $published->vid) {
    $my_revision = $published;
  }
  else {
    $query = db_select('node_revision', 'r');
    $query->addJoin('LEFT OUTER', 'workbench_moderation_node_history', 'm', 'r.vid = m.vid');
    $query->condition('m.vid', $node->vid)
      ->orderBy('m.hid', 'DESC')
      ->fields('m')
      ->fields('r', array('nid', 'vid', 'title', 'timestamp'));
    $my_revision = $query->execute()->fetchObject();

    // This might happen if you're turning workbench_moderation on and off, but
    // it should be really rare. Workbench_moderation must have recorded a
    // current revision, and then the node table must contain a different and
    // unpublished revision.
    if (!$my_revision) {
      $my_revision = (object) array(
        'hid' => NULL,
        'nid' => $node->nid,
        'vid' => $node->vid,
        'from_state' => workbench_moderation_state_none(),
        'state' => workbench_moderation_state_none(),
        'uid' => $node->uid,
        'stamp' => $node->changed,
        'published' => 0,
        'is_current' => 0,
      );
    }
  }
  // Add my revision to the array.
  $node->workbench_moderation['my_revision'] = $my_revision;
}

/**
 * Utility function to load the current revision of a node.
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   The current node according to moderation.
 */
function workbench_moderation_node_current_load($node) {
  // Is there a current revision?
  if (isset($node->workbench_moderation['current']->vid)) {
    // Ensure that we will return the current revision
    if ($node->vid != $node->workbench_moderation['current']->vid) {
      $node = node_load($node->nid, $node->workbench_moderation['current']->vid);
    }
  }
  return $node;
}


/**
 * Utility function to load the live revision of a node.
 *
 * This is encapsulated so that changes to how the moderation data is stored
 * will not impact the API.
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   The node object of the live revision.
 */
function workbench_moderation_node_live_load($node) {
  // Is there a live revision of this node?
  if (isset($node->workbench_moderation['published']->vid)) {
    return node_load($node->nid, $node->workbench_moderation['published']->vid);
  }
}


/**
 * Utility function to determine if this node is in the live state.
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return
 *   Boolean TRUE if this is the current revision. FALSE if not.
 */
function workbench_moderation_node_is_current($node) {
  if (isset($node->workbench_moderation['published']->vid) && isset($node->workbench_moderation['current']->vid)) {
    if ($node->workbench_moderation['published']->vid == $node->workbench_moderation['current']->vid) {
      return TRUE;
    }
    return FALSE;
  }
  // If not set, then TRUE.
  return TRUE;
}

/**
 * Get a list of all moderation states.
 *
 * @return
 *   An array of state objects, keyed by state name and ordered by weight. Each
 *   state object has name, description, and weight properties.
 */
function workbench_moderation_states() {
  $states = &drupal_static(__FUNCTION__);
  if (!isset($states)) {
    $states = db_select('workbench_moderation_states', 'states')
      ->fields('states', array('name', 'label', 'description', 'weight'))
      ->orderBy('states.weight', 'ASC')
      ->execute()
      ->fetchAllAssoc('name');
  }

  return $states;
}

/**
 * Generate an array of moderation states suitable for use as Form API #options.
 *
 * @return
 *   An array of states with machine names as keys and labels as values.
 */
function workbench_moderation_state_labels() {
  $labels = &drupal_static(__FUNCTION__);

  if (!isset($labels)) {
    $labels = array();
    foreach (workbench_moderation_states() as $machine_name => $state) {
      $labels[$machine_name] = $state->label;
    }
  }

  return $labels;
}

/**
 * Get the label for a state based on its machine name.
 *
 * @param type $machine_name
 *   The machine name of the state.
 * @return
 *   An unsanitized label or an empty string if the state does not exist.
 */
function workbench_moderation_state_label($machine_name) {
  $labels = workbench_moderation_state_labels();
  return isset($labels[$machine_name]) ? $labels[$machine_name] : '';
}

/**
 * Get information about a single moderation state.
 *
 * @param type $machine_name
 *   The machine name of the state.
 * @return
 *   An object of information about the state or FALSE if the state does not exist.
 */
function workbench_moderation_state_load($machine_name) {
  $states = workbench_moderation_states();
  if (isset($states[$machine_name])) {
    return $states[$machine_name];
  }
  return FALSE;
}

/**
 * Save a new or existing moderation state.
 *
 * Moderation state names must be unique, so saving a state object with a
 * non-unique name updates the existing state.
 *
 * Invokes hook_workbench_moderation_state_save().
 *
 * @param $state
 *   An object with name, description, and weight properties.
 *
 * @return int
 *   Returns MergeQuery::STATUS_INSERT or MergeQuery::STATUS_UPDATE depending
 *   on if this INSERT'ing a new transation or UPDATE'ing an existing one.
 *
 * @see hook_workbench_moderation_state_save()
 */
function workbench_moderation_state_save($state) {
  $status = db_merge('workbench_moderation_states')
    ->key(array('name' => $state->name))
    ->fields((array) $state)
    ->execute();

  foreach (module_implements('workbench_moderation_state_save') as $module) {
    // Don't call this function! That would lead to infinite recursion.
    if ($module !== 'workbench_moderation') {
      module_invoke($module, 'workbench_moderation_state_save', $state, $status);
    }
  }

  return $status;
}

/**
 * Delete a moderation state.
 *
 * This function also deletes any transitions that reference the deleted
 * moderation state.
 *
 * Invokes hook_workbench_moderation_state_delete().
 *
 * @param $state
 *   An object with at least a name property.
 *
 * @see hook_workbench_moderation_state_delete().
 * @see hook_workbench_moderation_transition_delete().
 */
function workbench_moderation_state_delete($state) {
  foreach (module_implements('workbench_moderation_state_delete') as $module) {
    // Don't call this function! That would lead to infinite recursion.
    if ($module !== 'workbench_moderation') {
      module_invoke($module, 'workbench_moderation_state_delete', $state);
    }
  }

  db_delete('workbench_moderation_states')
    ->condition('name', $state->name)
    ->execute();

  // Delete related transitions, too.
  $query = db_select('workbench_moderation_transitions', 't')
    ->fields('t')
    ->condition(db_or()->condition('from_name', $state->name)->condition('to_name', $state->name))
    ->execute();

  while ($transition = $query->fetchObject()) {
    workbench_moderation_transition_delete($transition);
  }
}

/**
 * Get a list of all moderation state transitions.
 *
 * @return
 *   An array of transition objects, each with from_name and to_name properties
 *   that reference moderation states. The array is ordered by the weight of the
 *   'from' states, then by the weight of the 'to' states.
 */
function workbench_moderation_transitions() {
  $transitions = &drupal_static(__FUNCTION__);
  if (!isset($transitions)) {
    $query = db_select('workbench_moderation_transitions', 't')
      ->fields('t', array('id', 'name', 'from_name', 'to_name'));

    $alias_from = $query->addJoin('INNER', 'workbench_moderation_states', NULL, 't.from_name = %alias.name');
    $alias_to = $query->addJoin('INNER', 'workbench_moderation_states', NULL, 't.to_name = %alias.name');

    $query
      ->orderBy("$alias_from.weight", 'ASC')
      ->orderBy("$alias_to.weight", 'ASC');

    $transitions = $query->execute()->fetchAll();
  }
  return $transitions;
}

/**
 * Saves a moderation state transition.
 *
 * Invokes hook_workbench_moderation_transition_save().
 *
 * @param $transition
 *   An object with from_name and to_name properties that reference moderation
 *   states.
 *
 * @return int
 *   Returns MergeQuery::STATUS_INSERT or MergeQuery::STATUS_UPDATE depending
 *   on if this INSERT'ing a new transation or UPDATE'ing an existing one.
 *
 * @see hook_workbench_moderation_transition_save()
 */
function workbench_moderation_transition_save($transition) {
  $status = db_merge('workbench_moderation_transitions')
    ->key(array(
      'name' => $transition->name,
      'from_name' => $transition->from_name,
      'to_name' => $transition->to_name,
    ))
    ->fields((array) $transition)
    ->execute();

  foreach (module_implements('workbench_moderation_transition_save') as $module) {
    // Don't call this function! That would lead to infinite recursion.
    if ($module !== 'workbench_moderation') {
      module_invoke($module, 'workbench_moderation_transition_save', $transition, $status);
    }
  }

  return $status;
}

/**
 * Deletes a moderation state transition.
 *
 * Invoke hook_workbenech_moderation_tranisiton_delete().
 *
 * @param $transition
 *   An object with from_name and to_name properties that reference moderation
 *   states.
 *
 * @see hook_workbench_moderation_transition_delete().
 */
function workbench_moderation_transition_delete($transition) {
  foreach (module_implements('workbench_moderation_transition_delete') as $module) {
    // Don't call this function! That would lead to infinite recursion.
    if ($module !== 'workbench_moderation') {
      module_invoke($module, 'workbench_moderation_transition_delete', $transition);
    }
  }

  db_delete('workbench_moderation_transitions')
    ->condition('from_name', $transition->from_name)
    ->condition('to_name', $transition->to_name)
    ->execute();
}

/**
 * Provides a list of possible next states for this node.
 *
 * This function is used in permissions checks, so it should never return
 * disallowed transitions.
 *
 * @param $current_state
 *   The current moderation state.
 * @param $account
 *   The user object being checked.
 * @param $node
 *   The node object being acted upon.
 *
 * @return
 *   If the user may moderate a change, return an array of possible state
 *   changes. Otherwise, return FALSE.
 */
function workbench_moderation_states_next($current_state, $account = NULL, $node) {
  $states = FALSE;

  // Make sure we have a current state.
  if (!$current_state) {
    $current_state = workbench_moderation_state_none();
  }

  if (empty($account)) {
    $account = $GLOBALS['user'];
  }

  if (user_access('bypass workbench moderation', $account)) {
    // Some functions expect an array of $state => $state pairs.
    $states = workbench_moderation_state_labels();
    unset($states[$current_state]);
  }
  else {
    // Get a list of possible transitions.
    $select = db_select('workbench_moderation_transitions', 'transitions')
      ->condition('transitions.from_name', $current_state)
      ->fields('transitions', array('to_name'))
      ->fields('states', array('label'));
    $select->join('workbench_moderation_states', 'states', 'transitions.to_name = states.name');

    $states = $select->execute()->fetchAllKeyed();

    // Checks whether the user has permission to make each transition. The
    // 'bypass workbench moderation' permission is accounted for in
    // workbench_moderation_state_allowed().
    if ($states) {
      foreach ($states as $machine_name => $label) {
        if (!workbench_moderation_state_allowed($account, $current_state, $machine_name, $node->type)) {
          unset($states[$machine_name]);
        }
      }
    }
  }

  $context = array('account' => $account, 'node' => $node);
  drupal_alter('workbench_moderation_states_next', $states, $current_state, $context);
  return $states;
}

/**
 * Provide quick moderation of nodes.
 *
 * Access is controlled by the menu router to these pseudo-form callbacks.
 * This function is also abstracted so that it can be called from any node
 * context.
 *
 * @see _workbench_moderation_moderate_access()
 * @see workbench_moderation_menu()
 * @see workbench_moderation_node_update()
 *
 * @param $node
 *   The node being acted upon.
 * @param $state
 *   The new moderation state requested.
 */
function workbench_moderation_moderate($node, $state) {
  global $user;

  $old_revision = $node->workbench_moderation['my_revision'];

  // Get the number of revisions for this node with vids greater than $node->vid
  $vid_count = db_select('node_revision', 'r')
    ->condition('r.nid', $node->nid)
    ->condition('r.vid', $node->vid, '>')
    ->countQuery()->execute()->fetchField();
  // If the number of greater vids is 0, then this is the most current revision
  $current = ($vid_count == 0);

  // Build a history record.
  $new_revision = (object) array(
    'from_state' => $old_revision->state,
    'state' => $state,
    'nid' => $node->nid,
    'vid' => $node->vid,
    'uid' => $user->uid,
    'is_current' => $current,
    'published' => ($state == workbench_moderation_state_published()),
    'stamp' => $_SERVER['REQUEST_TIME'],
  );

  // If this is the new 'current' moderation record, it should be the only one
  // flagged 'current' in {workbench_moderation_node_history}.
  if ($new_revision->is_current) {
    $query = db_update('workbench_moderation_node_history')
      ->condition('nid', $node->nid)
      ->fields(array('is_current' => 0))
      ->execute();
  }

  // If this revision is to be published, the new moderation record should be
  // the only one flagged 'published' in both
  // {workbench_moderation_node_history} AND {node_revision}
  if ($new_revision->published) {
    $query = db_update('workbench_moderation_node_history')
      ->condition('nid', $node->nid)
      ->fields(array('published' => 0))
      ->execute();
    $query = db_update('node_revision')
      ->condition('nid', $node->nid)
      ->fields(array('status' => 0))
      ->execute();
  }

  // Save the node history record.
  drupal_write_record('workbench_moderation_node_history', $new_revision);

  // Update the node's content_moderation information so that we can publish it
  // if necessary.
  $node->workbench_moderation['my_revision'] = $new_revision;
  if ($new_revision->is_current) {
    $node->workbench_moderation['current'] = $new_revision;
  }
  // Handle the published revision.
  if ($new_revision->published) {
    // If we're moderating a revision to the published state, mark the new
    // revision as the published revision.
    $node->workbench_moderation['published'] = $new_revision;
  }
  elseif (isset($node->workbench_moderation['published']) && $new_revision->vid == $node->workbench_moderation['published']->vid && $new_revision->from_state == workbench_moderation_state_published()) {
    // If we're moderating the published revision to a non-published state,
    // remove the workbench moderation 'published' property.
    $query = db_update('workbench_moderation_node_history')
      ->condition('hid', $node->workbench_moderation['published']->hid)
      ->fields(array('published' => 0))
      ->execute();
    unset($node->workbench_moderation['published']);
    $node->workbench_moderation['current']->unpublishing = TRUE;
  }

  // If we need to make changes to the currently published node we do this in a
  // shutdown function to avoid race conditions when running node_save() from
  // within a node submission. We need to change the published node:
  // - If we're moderating an unpublished revision and there is an existing
  //   published revision, make sure that the published revision is live.
  // - If we are moving to unpublished state we should make sure the published
  //   revision is the 'current' revision.
  if (!empty($node->workbench_moderation['published']) || !empty($node->workbench_moderation['current']->unpublishing)) {
    // Clone the node to make sure our data arrives intact in the shutdown
    // function. It might still be altered before the shutdown is reached.
    drupal_register_shutdown_function('workbench_moderation_store', clone $node);
  }
  else {
    entity_get_controller('node')->resetCache(array($node->nid));
  }

  // Notify other modules that the state was changed.
  module_invoke_all('workbench_moderation_transition', $node, $old_revision->state, $state);
}

/**
 * Shutdown callback for saving a node revision.
 *
 * This function is called by drupal_register_shutdown_function().
 * The purpose is to delay a node_save() call so that a live revision
 * is not called during hook_node_update().
 *
 * Instead, we delay the update until the new revision is saved. This way,
 * we can more safely call the revision and pick up changes to items
 * that are not revisioned (such as menu and path assignments).
 *
 * @see workbench_moderation_moderate()
 *
 * @param $node
 *   The node being saved.
 */
function workbench_moderation_store($node) {
  if (!isset($node->nid)) {
    watchdog('Workbench moderation', 'Failed to save node revision: node not passed to shutdown function.', array(), WATCHDOG_NOTICE);
    return;
  }
  watchdog('Workbench moderation', 'Saved node revision: %node as live version for node %live.', array('%node' => $node->vid, '%live' => $node->nid), WATCHDOG_NOTICE, l($node->title, 'node/' . $node->nid));

  // If we are saving a published node, work from the live revision, otherwise
  // make sure that the entry in the {node} table points to the current
  // revision.
  if (empty($node->workbench_moderation['current']->unpublishing)) {
    $live_revision = workbench_moderation_node_live_load($node);
    $live_revision->status = 1;
  }
  else {
    $live_revision = workbench_moderation_node_current_load($node);
    $live_revision->status = 0;
  }
  // Don't create a new revision.
  $live_revision->revision = 0;
  // Prevent another moderation record from being written.
  $live_revision->workbench_moderation['updating_live_revision'] = TRUE;

  // Reset flag from taxonomy_field_update() so that {taxonomy_index} values aren't written twice.
  $taxonomy_index_flag = &drupal_static('taxonomy_field_update', array());
  unset($taxonomy_index_flag[$node->nid]);

  // Save the node.
  $live_revision->revision = 0;
  $live_revision->path['pathauto'] = 0;
  node_save($live_revision);
}

/**
 * Helper function to redirect after a state change submission.
 *
 * @param $node
 *   The node being acted upon.
 * @param $state
 *   The new moderation state requested.
 */
function workbench_moderation_moderate_callback($node, $state) {
  if (!isset($_GET['token']) || !drupal_valid_token($_GET['token'], "{$node->nid}:{$node->vid}:$state")) {
    return MENU_ACCESS_DENIED;
  }

  workbench_moderation_moderate($node, $state);
  drupal_goto(isset($_GET['destination']) ? $_GET['destination'] : 'node/' . $node->nid . '/moderation');
}

/**
 * Generates a list of links to available moderation actions.
 *
 * @param $node
 *   The node being acted upon.
 * @param $url_options
 *   An array of options to pass, following the url() function syntax.
 *
 * @return
 *   A list of links to display with the revision.
 */
function workbench_moderation_get_moderation_links($node, $url_options = array()) {
  // Make sure that this node is moderated.
  if (!workbench_moderation_node_moderated($node)) {
    return;
  }

  // Build links to available moderation states.
  $links = array();
  $my_revision = $node->workbench_moderation['my_revision'];
  if ($my_revision->vid == $node->workbench_moderation['current']->vid
      && $next_states = workbench_moderation_states_next($my_revision->state, NULL, $node)) {
    foreach ($next_states as $state => $label) {
      $link = array_merge($url_options, array(
        'title' => t('Change to %label', array('%label' => workbench_moderation_state_label($state))),
        'href' => "node/{$node->nid}/moderation/{$node->vid}/change-state/{$state}",
      ));
      $link['query']['token'] = drupal_get_token("{$node->nid}:{$node->vid}:{$state}");
      $links[] = $link;
    }
  }

  return $links;
}

/**
 * Generates a moderation form for a node.
 *
 * The caller of this form needs to check whether the node is in moderation.
 *
 * @param $node
 *   The node being acted upon.
 *
 * @return $form
 *   A Drupal Forms API array.
 */
function workbench_moderation_moderate_form($form, &$form_state, $node, $destination = NULL) {
  global $user;
  $form = array();

  // Build links to available moderation states.
  $links = array();
  $my_revision = $node->workbench_moderation['my_revision'];
  if ($my_revision->vid == $node->workbench_moderation['current']->vid
      && $next_states = workbench_moderation_states_next($my_revision->state, $user, $node)) {
    $form['#destination'] = $destination;
    $form['node'] = array(
      '#type' => 'value',
      '#value' => $node,
    );
    $form['#attributes']['class'][] = 'workbench-moderation-moderate-form';
    $form['#attached']['css'][] = drupal_get_path('module', 'workbench_moderation') . '/css/workbench_moderation.css';
    $form['state'] = array(
      '#type' => 'select',
      '#title' => t('Moderation state'),
      '#title_display' => 'invisible',
      '#options' => $next_states,
      '#default_value' => _workbench_moderation_default_next_state($my_revision->state, $next_states),
    );
    $form['submit'] = array(
      '#type' => 'submit',
      '#value' => t('Apply'),
    );

    // Cache the form on first load to preserve the node for validation.
    // Otherwise, the node would be reloaded on submit, and there would be no
    // way to detect if the current revision has been changed.
    $form_state['cache'] = TRUE;
  }
  else {
    $form['#access'] = FALSE;
  }

  return $form;
}

function _workbench_moderation_default_next_state($current_state, $next_states) {
  $states = workbench_moderation_states();
  foreach ($states as $state_name => $state) {
    if ($state->weight > $states[$current_state]->weight && isset($next_states[$state_name])) {
      return $state_name;
    }
  }
}

function workbench_moderation_moderate_form_validate($form, &$form_state) {
  // Make sure that the revision that was shown to the user is still the current
  // revision before changing the current revision's state.
  $moderated_node = $form_state['values']['node'];
  $current_node = workbench_moderation_node_current_load(node_load($moderated_node->nid));
  if ($moderated_node->vid != $current_node->vid) {
    form_set_error('', t('The moderation state could not be changed because the draft has been updated by another user. Please review the current draft.'));
    // Redirect the form so that it rebuilds with the current revision.
    drupal_redirect_form($form_state);
  }
}

function workbench_moderation_moderate_form_submit($form, &$form_state) {
  if (_workbench_moderation_moderate_access($form_state['values']['node'], $form_state['values']['state'])) {
    workbench_moderation_moderate(node_load($form_state['values']['node']->nid, $form_state['values']['node']->vid), $form_state['values']['state']);
  }

  // This is not ideal, but if the form is invoked from a node's draft tab and
  // used to publish the node, the draft tab will not be available after
  // publishing, and Drupal's will throw an access denied error before it is
  // able to redirect to the published revision.
  if (!empty($form['#destination'])) {
    if ($form_state['values']['state'] == workbench_moderation_state_published()) {
      if ($uri = entity_uri('node', $form['node']['#value'])) {
        // Disable lookup of the path alias, since the path alias might get
        // changed by modules such as Pathauto.
        $uri['options']['alias'] = TRUE;
        $form_state['redirect'] = array($uri['path'], $uri['options']);
      }
    }
    else {
      $form_state['redirect'] = $form['#destination'];
    }
  }
}

/**
 * Sets status messages for a node.
 *
 * Note that these status messages aren't relevant to the session, only the
 * current page view.
 *
 * @see workbench_moderation_set_message()
 *
 * @param $context
 *   A string, either 'view' or 'edit'.
 * @param $node
 *   A node object. The current menu object will be used if it is a node and
 *   this variable was not set.
 */
function workbench_moderation_messages($context, $node = NULL) {
  global $user;
  static $workbench_moderation_messages_set;

  if (!user_access('view moderation messages')
      || (!$node && !($node = menu_get_object()))
      || !workbench_moderation_node_type_moderated($node->type)
      || $workbench_moderation_messages_set) {
    return;
  }

  $node_published = FALSE;
  $revision_published = FALSE;
  $revision_current = FALSE;
  $workbench_moderation_messages_set = TRUE;

  // For new content, this property will not be set.
  if (isset($node->workbench_moderation)) {
    $state = $node->workbench_moderation;
    if (!empty($state['published'])) {
      $node_published = TRUE;
    }
    if ($state['my_revision']->published) {
      $revision_published = TRUE;
    }
    if ($state['my_revision']->vid == $state['current']->vid) {
      $revision_current = TRUE;
    }
  }

  // An array of messages to add to the general workbench block.
  $info_block_messages = array();

  if ($context == 'view') {
    if (workbench_moderation_messages_shown($context, $node)) {
      // Prevent multiple moderation status.
      return;
    }
    $info_block_messages[] = array(
      'label' => t('Revision state'),
      'message' => check_plain(workbench_moderation_state_label($state['my_revision']->state)),
    );
    $info_block_messages[] = array(
      'label' => t('Most recent revision'),
      'message' => !empty($revision_current) ? t('Yes') : t('No'),
    );

    // Check node access.
    drupal_static('_node_revision_access', array(), TRUE);

    // Add a moderation form.
    if ($revision_current && !$revision_published && _workbench_moderation_access('update', $node) && $moderate_form = drupal_get_form('workbench_moderation_moderate_form', $node, "node/{$node->nid}/current-revision")) {
      if ($moderate_form = drupal_render($moderate_form)) {
        $info_block_messages[] = array(
          'label' => t('Set moderation state'),
          'message' => $moderate_form,
        );
      }
    }

    // Add an unpublish link.
    $next_states = workbench_moderation_states_next(workbench_moderation_state_published(), $user, $node);
    if ($revision_published && !empty($next_states) && $link = workbench_moderation_access_link(t('Unpublish this revision'), "node/{$node->nid}/moderation/{$node->vid}/unpublish")) {
      $info_block_messages[] = array(
        'label' => t('Actions'),
        'message' => $link,
      );
    }

    // Revision navigation links. This is disabled for the time being, since
    // node tabs are lost when navigating through old revisions.
    // @TODO remove this entirely?
    if (variable_get('workbench_moderation_show_revision_navigation', FALSE) && user_access('view revisions')) {
      $links = array();

      // Get previous and next revision ids.
      $args = array(':nid' => $node->nid, ':vid' => $node->vid);
      if ($prev_vid = db_query_range("SELECT nr.vid FROM {node_revision} nr WHERE nr.nid = :nid AND nr.vid < :vid ORDER BY nr.vid DESC", 0, 1, $args)->fetchField()) {
        $links[$prev_vid] = array('title' => t('Previous revision'), 'href' => "node/{$node->nid}/revisions/{$prev_vid}/view");
      }
      if ($next_vid = db_query_range("SELECT nr.vid FROM {node_revision} nr WHERE nr.nid = :nid AND nr.vid > :vid ORDER BY nr.vid ASC", 0, 1, $args)->fetchField()) {
        $links[$next_vid] = array('title' => t('Next revision'), 'href' => "node/{$node->nid}/revisions/{$next_vid}/view");
      }

      // If the current revision is next or previous, use the "node/%node/current-revision" path.
      if (($current = $state['current']->vid) && isset($links[$current])) {
        $links[$current]['href'] = "node/{$node->nid}/current-revision";
      }

      // If the published revision is next or previous, use the "node/%node" path.
      if (isset($state['published']) && ($published = $state['published']->vid) && isset($links[$published])) {
        $links[$published]['href'] = "node/{$node->nid}";
      }

      // Link it up, with access checks.
      foreach ($links as $key => $args) {
        $links[$key] = call_user_func_array('workbench_moderation_access_link', $args);
      }

      // Post the links in a non-repeating message.
      if (!empty($links)) {
        $info_block_messages[] = array(
          'label' => t('View'),
          'message' => implode(', ', $links),
        );
      }
    }
  }
  // @TODO: Clean these up.
  elseif ($context == 'edit') {
    if ($node_published && $revision_published) {
      $info_block_messages[] = array(
        'label' => t('Status'),
        'message' => t('New draft of live content.'),
      );
    }
    elseif ($node_published && !$revision_published) {
      $info_block_messages[] = array(
        'label' => t('Status'),
        'message' => t('New draft from current revision'),
      );
      $link = workbench_moderation_access_link(t('Create a new draft from the published revision.'), "node/{$node->nid}/revisions/{$state['published']->vid}/revert");
      $info_block_messages[] = array(
        'label' => t('Actions'),
        'message' => $link,
      );
    }
    else {
      // New content.
      /* MSMS: commented out, misleading message in case an editor epens the content to be edited
      $info_block_messages[] = array(
        'label' => t('New content'),
        'message' => t('Your draft will be placed in moderation.'),
      );
      */
    }
  }

  // Send the info block array to a static variable.
  workbench_moderation_set_message($info_block_messages);
}

/**
 * Prevent multiple moderation status.
 *
 * This function is a helper called from workbench_moderation_messages(). If the same node
 *  node_view() called multiple times in a page request there could be duplicate messages.
 *
 * @param $context
 *   A string, either 'view' or 'edit'. Currently only "view" is implemented.
 * @param $node
 *   A node object for which workbench_moderation_messages() is adding messages.
 * @return BOOL
 *  TRUE or FALSE for whether the given node has had messages added in the given
 *  context.
 */
function workbench_moderation_messages_shown($context, $node) {
  $shown = &drupal_static(__FUNCTION__);
  if (!empty($shown[$context][$node->nid])) {
    return TRUE;
  }
  $shown[$context][$node->nid] = TRUE;
  return FALSE;
}

/**
 * Builds a link for use in messages.
 *
 * @see workbench_moderation_messages()
 *
 * @param $text
 *   The link text to use.
 * @param $internal_path
 *   The Drupal path for the link.
 * @param $options
 *   Link options, following the format of url().
 *
 * @return
 *   A drupal-formatted HTML link.
 */
function workbench_moderation_access_link($text, $internal_path, $options = array()) {
  if (($item = menu_get_item($internal_path)) && !empty($item['access'])) {
    return l($text, $internal_path, $options);
  }
}

/**
 * Stores status messages for delivery.
 *
 * This function stores up moderation messages to be passed on to workbench_moderation_workbench_block().
 *
 * This function uses a static variable so that function can be called more than
 * once and the array built up.
 *
 * @see workbench_moderation_workbench_block()
 * @see workbench_moderation_messages()
 *
 * @param $new_messages
 *   An array of messages to be added to the block.
 *
 * @return
 *   An array of messages to be added to the block.
 */
function workbench_moderation_set_message($new_messages = array()) {
  static $messages = array();
  $messages = array_merge($messages, $new_messages);
  return $messages;
}

/**
 * Implements hook_block_view_workbench_block().
 *
 * Show the editorial status of this node.
 */
function workbench_moderation_workbench_block() {
  $output = array();
  foreach (workbench_moderation_set_message() as $message) {
    $output[] = t('!label: <em>!message</em>', array('!label' => $message['label'], '!message' => $message['message']));
  }

  return $output;
}


/**
 * Implementation of hook_workbench_moderation_transition().
 */
function workbench_moderation_workbench_moderation_transition($node, $previous_state, $new_state) {
  if (module_exists('trigger')) {
    workbench_moderation_trigger_transition($node, $previous_state, $new_state);
  }

  if (module_exists('rules')){
    rules_invoke_event('workbench_moderation_after_moderation_transition', $node, $previous_state, $new_state);
  }
}

/**
 * Implements hook_trigger_info().
 *
 * Creates a trigger for each transition.
 */
function workbench_moderation_trigger_info() {

  $output = array(
    'workbench_moderation' => array(
      'workbench_moderation_transition' => array(
        'label' => t('After any transition between states occurs.'),
      ),
    ),
  );

  // Get all transitions.
  $transitions = workbench_moderation_transitions();

  // Add a trigger for each transition.
  foreach ($transitions as $transition_definition) {
    $transition_string = 'wmt_' . $transition_definition->from_name . '__' . $transition_definition->to_name;
    // Hash this string if it's longer than the db field size
    if (strlen($transition_string) > 32) {
      $transition_string = md5($transition_string);
    }

    $output['workbench_moderation'][$transition_string] = array(
      'label' => t('Transition from the state %from_name to %to_name occurs.', array('%from_name' => $transition_definition->from_name, '%to_name' => $transition_definition->to_name)),
    );
  }

  return $output;
}

/**
 * transition trigger: Run actions associated with an arbitrary event.
 *
 * This function is executed after a transition takes place.
 *
 * @param $node
 *   The node undergoing the transition.
 * @param $from_state
 *   The previous workbench moderation state.
 * @param $state
 *   The new workbench moderation state.
 */
function workbench_moderation_trigger_transition($node, $from_state, $state, $a3 = NULL, $a4 = NULL) {
  // Ask the trigger module for all actions enqueued for the 'transition' trigger.
  $aids = trigger_get_assigned_actions('workbench_moderation_transition');
  // prepare a basic context, indicating group and "hook", and call all the
  // actions with this context as arguments.
  $context = array(
    'group' => 'workbench_moderation',
    'hook' => 'transition',
    'from_state' => $from_state,
    'state' => $state,
  );
  actions_do(array_keys($aids), $node, $context, $a3, $a4);


  // Ask the trigger module for all actions enqueued for this specific transition.
  $transition_string = 'wmt_' . $from_state . '__' . $state;
  // Hash this string if it's longer than the db field size
  if (strlen($transition_string) > 32) {
    $transition_string = md5($transition_string);
  }
  $aids = trigger_get_assigned_actions($transition_string);
  $context['hook'] = $transition_string;

  actions_do(array_keys($aids), $node, $context, $a3, $a4);
}

/**
 * Implements hook_action_info().
 */
function workbench_moderation_action_info() {
  $info = array();
  $info['workbench_moderation_set_state_action'] = array(
    'type' => 'node',
    'label' => t('Set moderation state'),
    'configurable' => TRUE,
    'triggers' => array('node_presave', 'node_insert', 'node_update', 'workbench_moderation_transition'),
  );

  // Get all workbench transitions.
  $transitions = workbench_moderation_transitions();

  // Add a trigger for each transition.
  foreach ($transitions as $transition_definition) {
    $transition_string = 'wmt_' . $transition_definition->from_name . '__' . $transition_definition->to_name;
    // Hash this string if it's longer than the db field size
    if (strlen($transition_string) > 32) {
      $transition_string = md5($transition_string);
    }

    $info['workbench_moderation_set_state_action']['triggers'][] = $transition_string;
  }

  return $info;
}

/**
 * Form builder; Prepare a form for possible moderation states.
 */
function workbench_moderation_set_state_action_form($context) {
  $form = array();

  $form['state'] = array(
    '#type' => 'select',
    '#options' => workbench_moderation_state_labels(),
    '#default_value' => isset($context['state']) ? $context['state'] : '',
  );

  return $form;
}

/**
 * Process workbench_moderation_set_state_action_form form submissions.
 */
function workbench_moderation_set_state_action_submit($form, $form_state) {
  return array('state' => $form_state['values']['state']);
}

/**
 * Changes the moderation state for a given node.
 */
function workbench_moderation_set_state_action($node, $context) {
  if (empty($context['state'])) return;

  // Check access to perform this moderation, on the latest revision of the node
  $node = workbench_moderation_node_current_load($node);
  if (_workbench_moderation_moderate_access($node, $context['state'])) {
    $node->workbench_moderation_state_new = $context['state'];
    $node->revision = 1;
    $node->log = "Bulk moderation state change.";
    node_save($node);

    watchdog('action', 'Change node %nid moderation state to %state.', array('%nid' => $node->nid, '%state' => $context['state']));
  }
  else {
    drupal_set_message(t('You do not have permission to moderate %node', array('%node' => $node->title)), 'warning');
  }
}

/**
 * Implements hook_ctools_plugin_directory() to let the system know
 * where our task and task_handler plugins are.
 */
function workbench_moderation_ctools_plugin_directory($owner, $plugin_type) {
  if ($owner == 'page_manager') {
    return 'plugins/page_manager/' . $plugin_type;
  }
}

/**
 * Implements hook_ctools_plugin_api().
 */
function workbench_moderation_ctools_plugin_api($module, $api) {

  if ($module == 'page_manager' && $api == 'pages_default') {
    return array('version' => 1);
  }
}

/**
 * Implement hook_migrate_api().
 */
function workbench_moderation_migrate_api() {
  return array('api' => 2);
}

/**
 * Implements hook_entity_info().
 */
function workbench_moderation_entity_info() {
  // Entification of transitions, for use with an entity reference field.
  $entity_info['workbench_moderation_transition'] = array(
    'label' => t('Workbench Moderation Transition'),
    'label callback' => 'workbench_moderation_transition_label_callback',
    'entity class' => 'Entity',
    'controller class' => 'EntityAPIController',
    'access callback' => 'workbench_moderation_transition_access',
    'base table' => 'workbench_moderation_transitions',
    'fieldable' => FALSE,
    'module' => 'workbench_moderation',
    'entity keys' => array(
      'id' => 'id',
    ),
  );

  return $entity_info;
}

/**
 * Wrapper for user_access to admin workbench_moderation.
 */
function workbench_moderation_transition_access($op, $profile = NULL, $account = NULL) {
  return user_access('administer workbench moderation');
}

/**
 * Label callback for workbench_moderation_transitions, for reference fields.
 */
function workbench_moderation_transition_label_callback($workbench_moderation_transition, $type) {
  return empty($workbench_moderation_transition->name) ? 'Unnamed Workbench Moderation Transition' : $workbench_moderation_transition->name;
}

/**
 * Fetch a workbench_moderation_transition object.
 *
 * @param int $id
 *   Integer specifying the workbench_moderation_transition id.
 * @param bool $reset
 *   A boolean indicating that the internal cache should be reset.
 *
 * @return obj
 *   A fully-loaded $workbench_moderation_transition object,
 *   or FALSE if it cannot be loaded.
 *
 * @see workbench_moderation_transition_load_multiple()
 */
function workbench_moderation_transition_load($id, $reset = FALSE) {
  $workbench_moderation_transition = workbench_moderation_transition_load_multiple(array($id), array(), $reset);
  return reset($workbench_moderation_transition);
}

/**
 * Load multiple workbench_moderation_transition based on certain conditions.
 *
 * @param array $ids
 *   An array of workbench_moderation_transition IDs.
 * @param array $conditions
 *   An array of conditions to match against the
 *   {workbench_moderation_transition} table.
 * @param bool $reset
 *   A boolean indicating that the internal cache should be reset.
 *
 * @return array
 *   An array of workbench_moderation_transition objects, indexed by wmpid.
 *
 * @see entity_load()
 * @see workbench_moderation_transition_load()
 */
function workbench_moderation_transition_load_multiple($ids = array(), $conditions = array(), $reset = FALSE) {
  return entity_load('workbench_moderation_transition', $ids, $conditions, $reset);
}

/**
 * Implements hook_node_export_node_alter().
 *
 * Manipulate a node on export.
 *
 * @param &$node
 *   The node to alter.
 * @param $original_node
 *   The unaltered node.
 */
function workbench_moderation_node_export_node_alter(&$node, $original_node) {

  // Don't proceed if moderation is not enabled on this content type
  if (!workbench_moderation_node_type_moderated($node->type)) {
    return;
  }

  //Set the current state to be the same as the current revision's state.
  if(!isset($node->workbench_moderation_state_current) && isset($node->workbench_moderation) && isset($node->workbench_moderation['current'])){
    $node->workbench_moderation_state_current = $node->workbench_moderation['current']->state;
  }

  // Set default moderation state values if they are not set.
  if (!isset($node->workbench_moderation_state_current)) {
    $node->workbench_moderation_state_current = ($node->status ? workbench_moderation_state_published() : workbench_moderation_state_none());
  };

  if (isset($node->workbench_moderation_state_current)) {
    // Set the new state to be the same as the current.
    $node->workbench_moderation_state_new = $node->workbench_moderation_state_current;
  }

  //Node revisions will not be exported so remove moderation states tied to revisions
  unset($node->workbench_moderation);
}

/**
 * Implements hook_node_export_node_import_alter().
 */
function workbench_moderation_node_export_node_import_alter(&$node, $original_node, $save) {
  // Don't proceed if moderation is not enabled on this content type
  if (!workbench_moderation_node_type_moderated($node->type)) {
    return;
  }
  $node->revision = 1;
}
