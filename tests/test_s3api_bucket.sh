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

source ./tests/setup.sh
source ./tests/util.sh
source ./tests/util_aws.sh
source ./tests/util_create_bucket.sh
source ./tests/util_file.sh
source ./tests/util_lock_config.sh
source ./tests/util_tags.sh
source ./tests/util_users.sh
source ./tests/test_aws_root_inner.sh
source ./tests/test_common.sh
source ./tests/test_common_acl.sh
source ./tests/commands/copy_object.sh
source ./tests/commands/delete_bucket_policy.sh
source ./tests/commands/delete_object_tagging.sh
source ./tests/commands/get_bucket_acl.sh
source ./tests/commands/get_bucket_policy.sh
source ./tests/commands/get_bucket_versioning.sh
source ./tests/commands/get_object.sh
source ./tests/commands/get_object_attributes.sh
source ./tests/commands/get_object_legal_hold.sh
source ./tests/commands/get_object_lock_configuration.sh
source ./tests/commands/get_object_retention.sh
source ./tests/commands/get_object_tagging.sh
source ./tests/commands/list_object_versions.sh
source ./tests/commands/put_bucket_acl.sh
source ./tests/commands/put_bucket_policy.sh
source ./tests/commands/put_bucket_versioning.sh
source ./tests/commands/put_object.sh
source ./tests/commands/put_object_legal_hold.sh
source ./tests/commands/put_object_lock_configuration.sh
source ./tests/commands/put_object_retention.sh
source ./tests/commands/put_public_access_block.sh
source ./tests/commands/select_object_content.sh

export RUN_USERS=true

# create-bucket
@test "test_create_delete_bucket_aws" {
  test_common_create_delete_bucket "aws"
}

@test "test_create_bucket_invalid_name" {
  test_create_bucket_invalid_name_aws_root
}

# delete-bucket - test_create_delete_bucket_aws

# delete-bucket-policy
@test "test_get_put_delete_bucket_policy" {
  if [[ -n $SKIP_POLICY ]]; then
    skip "will not test policy actions with SKIP_POLICY set"
  fi
  test_common_get_put_delete_bucket_policy "aws"
}

# delete-bucket-tagging
@test "test-set-get-delete-bucket-tags" {
  test_common_set_get_delete_bucket_tags "aws"
}

# get-bucket-acl
@test "test_get_bucket_acl" {
  test_get_bucket_acl_aws_root
}

# get-bucket-location
@test "test_get_bucket_location" {
  test_common_get_bucket_location "aws"
}

# get-bucket-policy - test_get_put_delete_bucket_policy

# get-bucket-tagging - test_set_get_delete_bucket_tags

@test "test_head_bucket_invalid_name" {
  if head_bucket "aws" ""; then
    fail "able to get bucket info for invalid name"
  fi
}

# test listing buckets on versitygw
@test "test_list_buckets" {
  test_common_list_buckets "s3api"
}

@test "test_put_bucket_acl" {
  test_common_put_bucket_acl "s3api"
}

@test "test_head_bucket" {
  run setup_bucket "aws" "$BUCKET_ONE_NAME"
  assert_success

  head_bucket "aws" "$BUCKET_ONE_NAME" || fail "error getting bucket info"
  log 5 "INFO:  $bucket_info"
  region=$(echo "$bucket_info" | grep -v "InsecureRequestWarning" | jq -r ".BucketRegion" 2>&1) || fail "error getting bucket region: $region"
  [[ $region != "" ]] || fail "empty bucket region"
  bucket_cleanup "aws" "$BUCKET_ONE_NAME"
}

@test "test_head_bucket_doesnt_exist" {
  run setup_bucket "aws" "$BUCKET_ONE_NAME"
  assert_success

  head_bucket "aws" "$BUCKET_ONE_NAME"a || local info_result=$?
  [[ $info_result -eq 1 ]] || fail "bucket info for non-existent bucket returned"
  [[ $bucket_info == *"404"* ]] || fail "404 not returned for non-existent bucket info"
  bucket_cleanup "aws" "$BUCKET_ONE_NAME"
}