RSpec.describe Requirements::Form::AccessLimitChecker do
  describe ".call" do
    let(:user) { build :user, organisation_content_id: "my-org" }

    it "returns no issues when there is no access limit" do
      edition = build(:edition)
      issues = described_class.call(edition, user)
      expect(issues).to be_empty
    end

    it "returns an issue when the edition has no primary org" do
      edition = build(:edition, :access_limited)
      issues = described_class.call(edition, user)
      expect(issues).to have_issue(:access_limit, :no_primary_org)
    end

    context "when edition is access limited to some orgs" do
      let(:edition) { build(:edition, :access_limited, created_by: user) }

      it "returns an issue when the user is not in the orgs" do
        allow(edition).to receive(:access_limit_organisation_ids).and_return(%w[another-org])
        issues = described_class.call(edition, user)
        expect(issues).to have_issue(:access_limit, :not_in_orgs)
      end

      it "returns no issues when the user is in the orgs" do
        allow(edition).to receive(:access_limit_organisation_ids).and_return(%w[my-org])
        issues = described_class.call(edition, user)
        expect(issues).to be_empty
      end
    end

    context "when user has no organisation associated with account" do
      let(:user) { build(:user, organisation_content_id: nil) }

      it "returns an issue when the user is not in the orgs" do
        edition = build(:edition, :access_limited, created_by: user)
        issues = described_class.call(edition, user)
        expect(issues).to have_issue(:access_limit, :user_has_no_org)
      end
    end
  end
end
