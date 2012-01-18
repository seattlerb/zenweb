class MiniTest::Unit::TestCase
  def self.ChdirTest path
    Module.new do
      define_method :setup do
        super
        @old_dir = Dir.pwd
        Dir.chdir path
      end

      define_method :teardown do
        super
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
end
