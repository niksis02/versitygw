#!/usr/bin/env bats

# Copyright 2024 Versity Software
# This file is licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

source ./tests/util/util_multipart_abort.sh

test_s3api_policy_abort_multipart_upload() {
  policy_file="policy_file"
  test_file="test_file"

  run create_large_file "$test_file"
  assert_success

  run setup_bucket "s3api" "$BUCKET_ONE_NAME"
  assert_success

  run setup_user_versitygw_or_direct "$USERNAME_ONE" "$PASSWORD_ONE" "user" "$BUCKET_ONE_NAME"
  assert_success
  # shellcheck disable=SC2154
  username=${lines[0]}
  password=${lines[1]}

  run setup_policy_with_double_statement "$TEST_FILE_FOLDER/$policy_file" "2012-10-17" \
    "Allow" "$USERNAME_ONE" "s3:PutObject" "arn:aws:s3:::$BUCKET_ONE_NAME/*" \
    "Deny" "$USERNAME_ONE" "s3:AbortMultipartUpload" "arn:aws:s3:::$BUCKET_ONE_NAME/*"
  assert_success
  # shellcheck disable=SC2154

  run put_bucket_policy "s3api" "$BUCKET_ONE_NAME" "$TEST_FILE_FOLDER/$policy_file"
  assert_success

  run create_multipart_upload_with_user "$BUCKET_ONE_NAME" "$test_file" "$username" "$password"
  assert_success
  # shellcheck disable=SC2154
  upload_id="$output"

  run check_abort_access_denied "$BUCKET_ONE_NAME" "$test_file" "$upload_id" "$username" "$password"
  assert_success

  run setup_policy_with_single_statement "$TEST_FILE_FOLDER/$policy_file" "2012-10-17" "Allow" "$USERNAME_ONE" "s3:AbortMultipartUpload" "arn:aws:s3:::$BUCKET_ONE_NAME/*"
  assert_success

  run put_bucket_policy "s3api" "$BUCKET_ONE_NAME" "$TEST_FILE_FOLDER/$policy_file"
  assert_success

  run abort_multipart_upload_with_user "$BUCKET_ONE_NAME" "$test_file" "$upload_id" "$username" "$password"
  assert_success
}

test_s3api_policy_list_multipart_uploads() {
  policy_file="policy_file"
  test_file="test_file"

  run create_test_file "$policy_file"
  assert_success

  run create_large_file "$test_file"
  assert_success

  effect="Allow"
  principal="$USERNAME_ONE"
  action="s3:ListBucketMultipartUploads"
  resource="arn:aws:s3:::$BUCKET_ONE_NAME"

  run setup_user_versitygw_or_direct "$USERNAME_ONE" "$PASSWORD_ONE" "user" "$BUCKET_ONE_NAME"
  assert_success
  username=${lines[0]}
  password=${lines[1]}

  run setup_bucket "s3api" "$BUCKET_ONE_NAME"
  assert_success

  run setup_policy_with_single_statement "$TEST_FILE_FOLDER/$policy_file" "dummy" "$effect" "$principal" "$action" "$resource"
  assert_success

  run create_multipart_upload "$BUCKET_ONE_NAME" "$test_file"
  assert_success

  run list_multipart_uploads_with_user "$BUCKET_ONE_NAME" "$username" "$password"
  assert_failure
  assert_output -p "Access Denied"

  run put_bucket_policy "s3api" "$BUCKET_ONE_NAME" "$TEST_FILE_FOLDER/$policy_file"
  assert_success

  run list_check_multipart_upload_key "$BUCKET_ONE_NAME" "$username" "$password" "$test_file"
  assert_success
}

test_s3api_policy_list_upload_parts() {
  policy_file="policy_file"
  test_file="test_file"

  run create_test_files "$policy_file"
  assert_success "error creating test files"

  run create_large_file "$test_file"
  assert_success "error creating large file"

  run setup_bucket "s3api" "$BUCKET_ONE_NAME"
  assert_success "error setting up bucket"

  run setup_user "$USERNAME_ONE" "$PASSWORD_ONE" "user"
  assert_success "error creating user '$USERNAME_ONE'"

  run setup_policy_with_single_statement "$TEST_FILE_FOLDER/$policy_file" "2012-10-17" "Allow" "$USERNAME_ONE" "s3:PutObject" "arn:aws:s3:::$BUCKET_ONE_NAME/*"
  assert_success "error setting up policy"

  run put_bucket_policy "s3api" "$BUCKET_ONE_NAME" "$TEST_FILE_FOLDER/$policy_file"
  assert_success "error putting policy"

  run create_upload_and_test_parts_listing "$test_file" "$policy_file"
  assert_success "error creating upload and testing parts listing"
}