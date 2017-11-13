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

require 'spec_helper'

describe MoveWorkPackageService, type: :model do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:work_package) do
    FactoryGirl.build_stubbed(:stubbed_work_package)
  end
  let(:type) { FactoryGirl.build_stubbed(:type) }
  let(:project) { FactoryGirl.build_stubbed(:project) }

  let(:instance) { described_class.new(work_package, user) }
  let(:child_service_result) do
    ServiceResult.new success: true,
                      result: [work_package],
                      errors: []
  end

  context 'when copying' do
    let(:expected_attributes) { { project: project } }

    before do
      copy_double = double('copy service double')

      expect(WorkPackages::CopyService)
        .to receive(:new)
        .with(user: user,
              work_package: work_package)
        .and_return(copy_double)

      expect(copy_double)
        .to receive(:call)
        .with(attributes: expected_attributes)
        .and_return(child_service_result)
    end

    it 'returns the work_package and calls the copy service' do
      expect(instance.call(project, nil, copy: true))
        .to eql work_package
    end

    context 'when providing a type and attributes' do
      let(:expected_attributes) do
        { project: project,
          type: type,
          subject: 'blubs' }
      end

      it 'returns the work_package and calls the update service' do
        expect(instance.call(project, type, attributes: { subject: 'blubs' }, copy: true))
          .to eql work_package
      end
    end
  end

  context 'when moving' do
    let(:expected_attributes) { { project: project } }

    before do
      update_double = double('update service double')

      expect(WorkPackages::UpdateService)
        .to receive(:new)
        .with(user: user,
              work_package: work_package)
        .and_return(update_double)

      expect(update_double)
        .to receive(:call)
        .with(attributes: expected_attributes)
        .and_return(child_service_result)
    end

    it 'returns the work_package and calls the update service' do
      expect(instance.call(project))
        .to eql work_package
    end

    context 'when providing a type and attributes' do
      let(:expected_attributes) do
        { project: project,
          type: type,
          subject: 'blubs' }
      end

      it 'returns the work_package and calls the update service' do
        expect(instance.call(project, type, attributes: { subject: 'blubs' }))
          .to eql work_package
      end
    end
  end
end
