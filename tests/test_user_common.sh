#!/usr/bin/env bats

source ./tests/setup.sh
source ./tests/util_users.sh
source ./tests/util.sh
source ./tests/util_bucket_create.sh
source ./tests/commands/list_buckets.sh

test_admin_user() {
  if [[ $# -ne 1 ]]; then
    fail "test admin user command requires command type"
  fi

  admin_username="$USERNAME_ONE"
  admin_password="$PASSWORD_ONE"
  user_username="$USERNAME_TWO"
  user_password="$PASSWORD_TWO"

  setup_user "$admin_username" "$admin_password" "admin" || fail "error setting up admin user"

  if user_exists "$user_username"; then
    delete_user "$user_username" || fail "failed to delete user '$user_username'"
  fi
  create_user_with_user "$admin_username" "$admin_password" "$user_username" "$user_password" "user" || fail "failed to create user '$user_username'"

  setup_bucket "aws" "$BUCKET_ONE_NAME"
  delete_bucket_or_contents_if_exists "aws" "versity-gwtest-admin-bucket"
  create_bucket_with_user "aws" "versity-gwtest-admin-bucket" "$admin_username" "$admin_password" || fail "error creating bucket with admin user"

  bucket_one_found=false
  bucket_two_found=false
  list_buckets_with_user "aws" "$admin_username" "$admin_password" || fail "error listing buckets with admin user"
  # shellcheck disable=SC2154
  for bucket in "${bucket_array[@]}"; do
    if [ "$bucket" == "$BUCKET_ONE_NAME" ]; then
      bucket_one_found=true
    elif [ "$bucket" == "versity-gwtest-admin-bucket" ]; then
      bucket_two_found=true
    fi
    if [ $bucket_one_found == true ] && [ $bucket_two_found == true ]; then
      break
    fi
  done
  if [ $bucket_one_found == false ] || [ $bucket_two_found == false ]; then
    fail "not all expected buckets listed"
  fi
  change_bucket_owner "$admin_username" "$admin_password" "versity-gwtest-admin-bucket" "$user_username" || fail "error changing bucket owner"

  run delete_bucket "aws" "versity-gwtest-admin-bucket"
  assert_success "failed to delete bucket"

  delete_user "$user_username"
  delete_user "$admin_username"
}

test_create_user_already_exists() {
  if [[ $# -ne 1 ]]; then
    fail "test admin user command requires command type"
  fi

  username="$USERNAME_ONE"
  password="$PASSWORD_ONE"

  setup_user "$username" "123456" "admin" || fail "error setting up user"
  if create_user "$username" "123456" "admin"; then
    fail "'user already exists' error not returned"
  fi

  delete_user "$username"
}

test_user_user() {
  if [[ $# -ne 1 ]]; then
    fail "test admin user command requires command type"
  fi

  username="$USERNAME_ONE"
  password="$PASSWORD_ONE"

  setup_user "$username" "$password" "user" || fail "error setting up user"
  delete_bucket_or_contents_if_exists "aws" "versity-gwtest-user-bucket"
  setup_bucket "aws" "$BUCKET_ONE_NAME"

  if create_bucket_with_user "aws" "versity-gwtest-user-bucket" "$username" "$password"; then
    fail "creating bucket with 'user' account failed to return error"
  fi
  # shellcheck disable=SC2154
  [[ $error == *"Access Denied"* ]] || fail "error message '$error' doesn't contain 'Access Denied'"

  create_bucket "aws" "versity-gwtest-user-bucket" || fail "error creating bucket"

  change_bucket_owner "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "versity-gwtest-user-bucket" "$username" || fail "error changing bucket owner"
  if change_bucket_owner "$username" "$password" "versity-gwtest-user-bucket" "admin"; then
    fail "user shouldn't be able to change bucket owner"
  fi

  list_buckets_with_user "aws" "$username" "$password" || fail "error listing buckets with user '$username'"
  bucket_found=false
  for bucket in "${bucket_array[@]}"; do
    if [ "$bucket" == "$BUCKET_ONE_NAME" ]; then
      fail "$BUCKET_ONE_NAME shouldn't show up in 'user' bucket list"
    elif [ "$bucket" == "versity-gwtest-user-bucket" ]; then
      bucket_found=true
    fi
  done
  if [ $bucket_found == false ]; then
    fail "user-owned bucket not found in user list"
  fi

  run delete_bucket "aws" "versity-gwtest-user-bucket"
  assert_success "failed to delete bucket"
  delete_user "$username"
}

test_userplus_operation() {
  if [[ $# -ne 1 ]]; then
    fail "test admin user command requires command type"
  fi

  username="$USERNAME_ONE"
  password="$PASSWORD_ONE"

  delete_bucket_or_contents_if_exists "aws" "versity-gwtest-userplus-bucket"
  setup_user "$username" "$password" "userplus" || fail "error creating user '$username'"
  setup_bucket "aws" "$BUCKET_ONE_NAME"

  create_bucket_with_user "aws" "versity-gwtest-userplus-bucket" "$username" "$password" || fail "error creating bucket with user '$username'"

  list_buckets_with_user "aws" "$username" "$password" || fail "error listing buckets with user '$username'"
  bucket_found=false
  for bucket in "${bucket_array[@]}"; do
    if [ "$bucket" == "$BUCKET_ONE_NAME" ]; then
      fail "$BUCKET_ONE_NAME shouldn't show up in 'userplus' bucket list"
    elif [ "$bucket" == "versity-gwtest-userplus-bucket" ]; then
      bucket_found=true
    fi
  done
  if [ $bucket_found == false ]; then
    fail "userplus-owned bucket not found in user list"
  fi

  if change_bucket_owner "$username" "$password" "versity-gwtest-userplus-bucket" "admin"; then
    fail "userplus shouldn't be able to change bucket owner"
  fi

  run delete_bucket "aws" "versity-gwtest-admin-bucket"
  assert_success "failed to delete bucket"
  delete_user "$username"
}