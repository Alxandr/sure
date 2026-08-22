#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/cut-version
source "${SCRIPT_DIR}/cut-version"

test::version::kind::not-prerelease-returns-empty() {
  local result

  result=$(version::kind "1.2.3")
  assert_equals "" "$result"
}

test::version::kind::alpha-prerelease-returns-alpha() {
  local result

  result=$(version::kind "1.2.3-alpha.4")
  assert_equals "alpha" "$result"
}

test::version::kind::beta-prerelease-returns-beta() {
  local result

  result=$(version::kind "1.2.3-beta.4")
  assert_equals "beta" "$result"
}

test::version::kind::rc-prerelease-returns-rc() {
  local result

  result=$(version::kind "1.2.3-rc.4")
  assert_equals "rc" "$result"
}

test::version::point::not-prerelease-returns-version() {
  local result

  result=$(version::point "1.2.3")
  assert_equals "1.2.3" "$result"
}

test::version::point::prerelease-returns-point-version() {
  local result

  result=$(version::point "1.2.3-alpha.4")
  assert_equals "1.2.3" "$result"
}

test::version::bump-point::increments-minor-and-resets-patch() {
  local result

  result=$(version::bump-point "1.2.3")
  assert_equals "1.3.0" "$result"
}

test::version::bump-point::treats-leading-zero-minor-as-decimal() {
  local result

  result=$(version::bump-point "1.08.3")
  assert_equals "1.9.0" "$result"
}

test::version::bump-fix::increments-patch() {
  local result

  result=$(version::bump-fix "1.2.3")
  assert_equals "1.2.4" "$result"
}

test::version::bump-fix::treats-leading-zero-patch-as-decimal() {
  local result

  result=$(version::bump-fix "1.2.09")
  assert_equals "1.2.10" "$result"
}

test::version::bump-prerelease::increments-alpha-number() {
  local result

  result=$(version::bump-prerelease "alpha" "1.2.3-alpha.4")
  assert_equals "1.2.3-alpha.5" "$result"
}

test::version::bump-prerelease::increments-beta-number() {
  local result

  result=$(version::bump-prerelease "beta" "1.2.3-beta.4")
  assert_equals "1.2.3-beta.5" "$result"
}

test::version::bump-prerelease::increments-rc-number() {
  local result

  result=$(version::bump-prerelease "rc" "1.2.3-rc.4")
  assert_equals "1.2.3-rc.5" "$result"
}

test::version::next-point::from-point-bumps-minor() {
  local result

  result=$(version::next-point "1.2.3")
  assert_equals "1.3.0" "$result"
}

test::version::next-point::from-prerelease-bumps-point-version() {
  local result

  result=$(version::next-point "1.2.3-rc.4")
  assert_equals "1.3.0" "$result"
}

test::version::next-fix::from-point-bumps-patch() {
  local result

  result=$(version::next-fix "1.2.3")
  assert_equals "1.2.4" "$result"
}

test::version::next-fix::from-prerelease-bumps-point-patch() {
  local result

  result=$(version::next-fix "1.2.3-rc.4")
  assert_equals "1.2.4" "$result"
}

test::version::next-alpha::from-point-bumps-minor-and-starts-alpha() {
  local result

  result=$(version::next-alpha "1.2.3")
  assert_equals "1.3.0-alpha.1" "$result"
}

test::version::next-alpha::from-alpha-increments-alpha() {
  local result

  result=$(version::next-alpha "1.2.3-alpha.4")
  assert_equals "1.2.3-alpha.5" "$result"
}

test::version::next-beta::from-point-bumps-minor-and-starts-beta() {
  local result

  result=$(version::next-beta "1.2.3")
  assert_equals "1.3.0-beta.1" "$result"
}

test::version::next-beta::from-alpha-starts-beta-on-same-point() {
  local result

  result=$(version::next-beta "1.2.3-alpha.4")
  assert_equals "1.2.3-beta.1" "$result"
}

test::version::next-beta::from-beta-increments-beta() {
  local result

  result=$(version::next-beta "1.2.3-beta.4")
  assert_equals "1.2.3-beta.5" "$result"
}

test::version::next-rc::from-point-bumps-minor-and-starts-rc() {
  local result

  result=$(version::next-rc "1.2.3")
  assert_equals "1.3.0-rc.1" "$result"
}

test::version::next-rc::from-alpha-starts-rc-on-same-point() {
  local result

  result=$(version::next-rc "1.2.3-alpha.4")
  assert_equals "1.2.3-rc.1" "$result"
}

test::version::next-rc::from-beta-starts-rc-on-same-point() {
  local result

  result=$(version::next-rc "1.2.3-beta.4")
  assert_equals "1.2.3-rc.1" "$result"
}

test::version::next-rc::from-rc-increments-rc() {
  local result

  result=$(version::next-rc "1.2.3-rc.4")
  assert_equals "1.2.3-rc.5" "$result"
}

test::step::update-version::updates-version-files-and-removes-backup() {
  CUT_VERSION_TEST_TMPDIR="$(mktemp -d)"
  trap 'rm -rf -- "${CUT_VERSION_TEST_TMPDIR}"' EXIT

  mkdir -p "${CUT_VERSION_TEST_TMPDIR}/charts/sure"
  printf '%s\n' "0.0.0" > "${CUT_VERSION_TEST_TMPDIR}/.sure-version"
  printf '%s\n' \
    "apiVersion: v2" \
    "name: sure" \
    "version: 0.0.0" \
    'appVersion: "0.0.0"' \
    > "${CUT_VERSION_TEST_TMPDIR}/charts/sure/Chart.yaml"

  cd "${CUT_VERSION_TEST_TMPDIR}"
  git() { return 0; }

  step::update-version "1.2.3"

  assert_equals "1.2.3" "$(< .sure-version)"
  assert_equals "version: 1.2.3" "$(sed -n '/^version:/p' charts/sure/Chart.yaml)"
  assert_equals 'appVersion: "1.2.3"' "$(sed -n '/^appVersion:/p' charts/sure/Chart.yaml)"
  assert "[[ ! -e charts/sure/Chart.yaml.bak ]]"
}
