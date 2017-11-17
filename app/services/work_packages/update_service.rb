#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::UpdateService
  include ::WorkPackages::Shared::UpdateAncestors

  attr_accessor :user,
                :work_package,
                :contract

  def initialize(user:, work_package:, contract: WorkPackages::UpdateContract)
    self.user = user
    self.work_package = work_package
    self.contract = contract
  end

  def call(attributes: {}, send_notifications: true)
    as_user_and_sending(send_notifications) do
      update(attributes)
    end
  end

  private

  def update(attributes)
    result = set_attributes(attributes)

    if result.success?
      cleanup(result)

      result.merge!(reschedule_related)
    end

    if save_if_valid(result)
      result.merge!(update_ancestors([work_package]))
    end

    result
  end

  def save_if_valid(result)
    if result.success?
      self_work_package, other_work_packages = result.result.partition { |r| r.id == work_package.id }

      unless self_work_package.first.save && other_work_packages.all? { |m| m.save(validate: false) }
        result.success = false
        result.errors += result.result.reject { |r| r.errors.empty? }.map(&:errors)
      end
    end

    result.success?
  end

  def update_dependent(attributes)
    result = ServiceResult.new(success: true, errors: [], result: [])

    cleanup(attributes) if result.success?

    result.merge!(reschedule_related)

    result
  end

  def set_attributes(attributes, wp = work_package)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: wp,
           contract: contract)
      .call(attributes)
  end

  def cleanup(result)
    changed_project = result.result.select(&:project_id_changed?)

    if changed_project.any?
      moved_work_packages = [work_package] + work_package.descendants
      delete_relations(moved_work_packages)
      move_time_entries(moved_work_packages)
    end

    changed_type = result.result.select(&:type_id_changed?)

    if changed_type.any?
      reset_custom_values(changed_type)
    end
  end

  def delete_relations(work_packages)
    unless Setting.cross_project_work_package_relations?
      Relation
        .non_hierarchy_of_work_package(work_packages)
        .destroy_all
    end
  end

  def move_time_entries(work_packages)
    project_id = work_packages.first.project_id

    TimeEntry
      .on_work_packages(work_packages)
      .update_all(project_id: project_id)
  end

  def reset_custom_values(work_packages)
    work_packages.each(&:reset_custom_values!)
  end

  def reschedule_related
    WorkPackages::SetScheduleService
      .new(user: user,
           work_packages: [work_package])
      .call(work_package.changed.map(&:to_sym))
  end

  def as_user_and_sending(send_notifications)
    result = nil

    WorkPackage.transaction do
      User.execute_as user do
        JournalManager.with_send_notifications send_notifications do
          result = yield

          if result.failure?
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    result
  end

  def call_and_assign(method, params, updated, errors)
    send(method, *params).tap do |updated_by_method, errors_by_method|
      errors += errors_by_method
      updated += updated_by_method
    end
  end
end
