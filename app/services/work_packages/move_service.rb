
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
      copy_with_descendants(attributes)
    else
      update(attributes)
    end
  end

  def copy_with_descendants(attributes)
    result = ServiceResult.new success: true, errors: [], result: []
    ancestors = {}

    work_package.self_and_descendants.order_by_ancestors('asc').each do |wp|
      attributes[:parent_id] = ancestors[wp.parent_id] || wp.parent_id

      copied = copy(wp, attributes)

      ancestors[wp.id] = copied.result.first.id

      result.merge!(copied)
    end

    result
  end

  def copy(wp, attributes)
    WorkPackages::CopyService
      .new(user: user,
           work_package: wp)
      .call(attributes: attributes)
  end

  def update(attributes)
    WorkPackages::UpdateService
      .new(user: user,
           work_package: work_package)
      .call(attributes: attributes)
  end
end
