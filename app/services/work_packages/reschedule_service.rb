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

class WorkPackages::RescheduleService
  include ::WorkPackages::Shared::ServiceContext

  attr_accessor :user,
                :work_package

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package
  end

  def call(date)
    in_context(true) do
      return if date.nil?

      update(date)
    end
  end

  def update(date)
    result = set_attributes(date)

    if result.success?
      result.merge!(reschedule_related(result.all_results))
    end

    persist(result)
  end

  def reschedule_related(work_packages)
    WorkPackages::SetScheduleService
      .new(user: user,
           work_packages: work_packages)
      .call(%i(start_date due_date))
  end

  def set_attributes(date)
    if work_package.leaf?
      reschedule(work_package, date)
    else
      reschedule_leaves(date)
    end
  end

  def set_dates(scheduled, attributes)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: scheduled,
           contract: WorkPackages::UpdateContract)
      .call(attributes)
  end

  def reschedule_leaves(date)
    injected = WorkPackages::ServiceResult.new(success: true, result: work_package)

    work_package.leaves.inject(injected) do |result, leaf|
      result.merge!(reschedule(leaf, date))
    end
  end

  def reschedule(scheduled, date)
    if scheduled.start_date.nil? || scheduled.start_date < date
      attributes = { due_date: date + scheduled.duration - 1,
                     start_date: date }

      set_dates(scheduled, attributes)
    else
      WorkPackages::ServiceResult.new(success: true, result: scheduled)
    end
  end

  def persist(result)
    return result unless result.success? && result.all_errors.empty?

    result.success = result.result.save && result.dependent_results.all? { |res| res.result.save(validate: false) }

    result
  end
end
