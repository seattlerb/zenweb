class MiniTest::Unit::TestCase
  def self.ChdirTest path
    Module.new do
      define_method :setup do
        super()
        @old_dir = Dir.pwd
        Dir.chdir path
      end

      define_method :teardown do
        super()
        Dir.chdir @old_dir
      end
    end
  end

  def assert_task name, deps = nil, type = Rake::FileTask
    @tasks << name
    assert_operator Rake::Task, :task_defined?, name

    task = Rake.application[name]
    assert_kind_of type, task
    assert_equal deps, task.prerequisites.sort, name if deps
  end

  def assert_tasks
    @tasks = []
    yield
    assert_empty Rake.application.tasks.map(&:name) - @tasks
  end

  def build_fake_site(*paths)
    paths.flatten.compact.each do |path|
      page = Zenweb::Page.new(site, path)
      page.content = "Content for #{path}"
      page.config = Zenweb::Config.new site, path
      page.config.h = {
        "title" => "Title for #{path}"
      }
      site.pages[path] = page
    end
  end
end

class Zenweb::Page
  attr_writer :content, :config
end

class Zenweb::Config
  attr_writer :h
end
