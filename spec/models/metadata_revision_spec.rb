# frozen_string_literal: true

RSpec.describe MetadataRevision do
  describe "#different_to?" do
    it "is true when data differs" do
      revision1 = build(:metadata_revision, change_note: "This")
      revision2 = build(:metadata_revision, change_note: "That")

      expect(revision1.different_to?(revision2)).to be true
    end

    it "is false when content is the same and only timestamps differ" do
      revision1 = build(:metadata_revision,
                        change_note: "Same",
                        created_at: 10.days.ago)
      revision2 = build(:metadata_revision,
                        change_note: "Same",
                        created_at: 10.weeks.ago)

      expect(revision1.different_to?(revision2)).to be false
    end
  end

  describe "#build_revision_update" do
    let(:existing_revision) do
      create(:metadata_revision, update_type: :minor)
    end

    it "returns the current revision if the update does not change it's content" do
      revision = existing_revision.build_revision_update(
        { update_type: existing_revision.update_type },
        build(:user),
      )

      expect(revision).to be(existing_revision)
    end

    it "returns a new revision if the update changes content" do
      revision = existing_revision.build_revision_update(
        { update_type: :major },
        build(:user),
      )

      expect(revision).not_to be(existing_revision)
      expect(revision).to be_new_record
    end
  end
end