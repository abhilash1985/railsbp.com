require 'spec_helper'

describe Build do
  include DelayedJobSpecHelper

  it { should belong_to(:repository) }

  context "after_save" do
    it "should call analyze" do
      Build.any_instance.expects(:analyze)
      Build.any_instance.expects(:set_position)
      Build.create
    end
  end

  context "#short_commit_id" do
    before { Repository.any_instance.stubs(:sync_github).returns(true) }
    subject { Factory(:build, :last_commit_id => "1234567890") }
    its(:short_commit_id) { should == "1234567" }
  end

  context "#analyze_path" do
    before do
      Repository.any_instance.stubs(:sync_github).returns(true)
      @repository = Factory(:repository, github_name: "flyerhzm/railsbp.com", name: "railsbp.com", git_url: "git://github.com/flyerhzm/railsbp.com.git")
    end
    subject { @build = @repository.builds.create(last_commit_id: "987654321") }
    its(:analyze_path) { should == Rails.root.join("builds/flyerhzm/railsbp.com/commit/987654321").to_s }
  end

  context "#analyze_file" do
    before do
      Repository.any_instance.stubs(:sync_github).returns(true)
      @repository = Factory(:repository, github_name: "flyerhzm/railsbp.com", name: "railsbp.com", git_url: "git://github.com/flyerhzm/railsbp.com.git")
    end
    subject { @build = @repository.builds.create(last_commit_id: "987654321") }
    its(:analyze_file) { should == Rails.root.join("builds/flyerhzm/railsbp.com/commit/987654321/rbp.html").to_s }
  end

  context "#templae_file" do
    before { Repository.any_instance.stubs(:sync_github).returns(true) }
    subject { @build = Factory(:build) }
    its(:template_file) { should == Rails.root.join("app/views/builds/_rbp.html.erb").to_s }
  end

  context "#analyze" do
    before do
      Repository.any_instance.stubs(:sync_github).returns(true)
      repository = Factory(:repository, github_name: "flyerhzm/railsbp.com", name: "railsbp.com", git_url: "git://github.com/flyerhzm/railsbp.com.git")
      @build = repository.builds.create(last_commit_id: "987654321")
    end

    it "should fetch remote git and analyze" do
      path = Rails.root.join("builds/flyerhzm/railsbp.com/commit/987654321").to_s
      template = Rails.root.join("app/views/builds/_rbp.html.erb").to_s
      File.expects(:exist?).with(path).returns(false)
      FileUtils.expects(:mkdir_p).with(path)
      FileUtils.expects(:cd).with(path)

      Git.expects(:clone).with("git://github.com/flyerhzm/railsbp.com.git", "railsbp.com")
      Dir.expects(:chdir).with("railsbp.com")

      rails_best_practices = mock
      RailsBestPractices::Analyzer.expects(:new).with(path + "/railsbp.com", "format" => "html", "silent" => true, "output-file" => path + "/rbp.html", "with-github" => true, "github-name" => "flyerhzm/railsbp.com", "last-commit-id" => "987654321", "template" => template).returns(rails_best_practices)
      rails_best_practices.expects(:analyze)
      rails_best_practices.expects(:output)

      runner = mock
      rails_best_practices.expects(:runner).returns(runner)
      runner.expects(:errors).returns([])
      FileUtils.expects(:rm_rf).with(path + "/railsbp.com")
      work_off
    end
  end
end
