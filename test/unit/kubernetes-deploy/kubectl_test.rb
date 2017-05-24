# frozen_string_literal: true
require 'test_helper'

class KubectlTest < KubernetesDeploy::TestCase
  def setup
    Open3.expects(:capture3).never
    super
  end

  def test_raises_if_initialized_with_null_context
    assert_raises_message(ArgumentError, "context is required") do
      KubernetesDeploy::Kubectl.new(namespace: 'test', context: nil, logger: test_logger, log_failure_by_default: true)
    end
  end

  def test_raises_if_initialized_with_null_namespace
    assert_raises_message(ArgumentError, "namespace is required") do
      KubernetesDeploy::Kubectl.new(namespace: nil, context: 'test', logger: test_logger, log_failure_by_default: true)
    end
  end

  def test_run_constructs_the_expected_command_and_returns_the_correct_values
    stub_open3(%w(kubectl get pods -a --output=json --namespace=testn --context=testc), resp: "{ items: [] }")

    out, err, st = build_kubectl.run("get", "pods", "-a", "--output=json")
    assert st.success?
    assert_equal "{ items: [] }", out
    assert_equal "", err
  end

  def test_run_omits_context_flag_if_use_context_is_false
    stub_open3(%w(kubectl get pods -a --output=json --namespace=testn), resp: "{ items: [] }")
    build_kubectl.run("get", "pods", "-a", "--output=json", use_context: false)
  end

  def test_run_omits_namespace_flag_if_use_namespace_is_false
    stub_open3(%w(kubectl get pods -a --output=json --context=testc), resp: "{ items: [] }")
    build_kubectl.run("get", "pods", "-a", "--output=json", use_namespace: false)
  end

  def test_run_logs_failures_when_log_failure_by_default_is_true_and_override_is_unspecified
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).twice
    build_kubectl(log_failure_by_default: true).run("get", "pods")
  end

  def test_run_logs_failures_when_log_failure_by_default_is_true_and_override_is_also_true
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).twice
    build_kubectl(log_failure_by_default: true).run("get", "pods", log_failure: true)
  end

  def test_run_does_not_log_failures_when_log_failure_by_default_is_true_and_override_is_false
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).never
    build_kubectl(log_failure_by_default: true).run("get", "pods", log_failure: false)
  end

  def test_run_does_not_log_failures_when_log_failure_by_default_is_false_and_override_is_unspecified
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).never
    build_kubectl(log_failure_by_default: false).run("get", "pods")
  end

  def test_run_does_not_log_failures_when_log_failure_by_default_is_false_and_override_is_also_false
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).never
    build_kubectl(log_failure_by_default: false).run("get", "pods", log_failure: false)
  end

  def test_run_logs_failures_when_log_failure_by_default_is_false_and_override_is_true
    stub_open3(%w(kubectl get pods --namespace=testn --context=testc), resp: "", err: "oops", success: false)
    test_logger.expects(:warn).twice
    build_kubectl(log_failure_by_default: false).run("get", "pods", log_failure: true)
  end

  private

  def build_kubectl(log_failure_by_default: true)
    KubernetesDeploy::Kubectl.new(namespace: 'testn', context: 'testc', logger: test_logger,
      log_failure_by_default: log_failure_by_default)
  end

  def stub_open3(command, resp:, err: "", success: true)
    Open3.expects(:capture3).with(*command).returns([resp, err, stub(success?: success)])
  end
end
