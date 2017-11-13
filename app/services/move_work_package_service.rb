
# Moves/copies an work_package to a new project and type
# Returns the moved/copied work_package on success, false on failure

class MoveWorkPackageService
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

    service_call = if options[:copy]
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

    service_call
      .result
      .first
  end
end
