
# Moves/copies an work_package to a new project and type

class WorkPackages::MoveService
  attr_accessor :work_package,
                :user

  def initialize(work_package, user)
    self.work_package = work_package
    self.user = user
  end

  def call(new_project, new_type = nil, options = {})
    attributes = options[:attributes] || {}
    attributes[:project] = new_project
    attributes[:type] = new_type if new_type
    attributes[:journal_notes] = options[:journal_note] if options[:journal_note]

    if options[:copy]
      WorkPackages::CopyService
        .new(user: user,
             work_package: work_package)
        .call(attributes: attributes)
    else
      WorkPackages::UpdateService
        .new(user: user,
             work_package: work_package)
        .call(attributes: attributes)
    end
  end
end
