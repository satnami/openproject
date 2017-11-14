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

class WorkPackages::CreateService
  include ::WorkPackages::Shared::UpdateAncestors

  attr_accessor :user, :work_package

  def initialize(user:)
    self.user = user
  end

  def call(attributes: {},
           work_package: WorkPackage.new,
           send_notifications: true)
    as_user_and_sending(send_notifications) do
      create(attributes, work_package)
    end
  end

  protected

  def create(attributes, work_package)
    result = set_attributes(attributes, work_package)

    result.success &&= work_package.save

    if result.success?
      result.merge!(reschedule_related(work_package))
      result.merge!(update_ancestors_all_attributes(result.result))
    else
      result.success = false
      result.errors << work_package.errors
    end

    result
  end

  def set_attributes(attributes, wp)
    WorkPackages::SetAttributesService
      .new(user: user,
           work_package: wp,
           contract: WorkPackages::CreateContract)
      .call(attributes)
  end

  def reschedule_related(work_package)
    result = WorkPackages::SetScheduleService
             .new(user: user,
                  work_packages: [work_package])
             .call

    unless result.success? && result.result.all?(&:save)
      result.sucess = false
      result.errors = result.result.select(&:changed?).map(&:errors)
    end

    result
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
end
