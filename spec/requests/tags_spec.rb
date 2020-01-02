# frozen_string_literal: true

RSpec.describe "Tags" do
  it_behaves_like "requests that assert edition state",
                  "tagging a non editable edition",
                  routes: { tags_path: %i[get patch] } do
    let(:edition) { create(:edition, :published) }
  end

  describe "GET /documents/:document/tags" do
    let(:tag_field) { build(:tag_field, type: "multi_tag") }
    let(:edition) do
      document_type = build(:document_type, tags: [tag_field])
      create(:edition, document_type_id: document_type.id)
    end

    it "returns successfully" do
      tag_name = SecureRandom.hex(8)
      stub_publishing_api_has_linkables(
        [{ "content_id" => SecureRandom.uuid, "internal_name" => tag_name }],
        document_type: tag_field.document_type,
      )
      get tags_path(edition.document)
      expect(response).to have_http_status(:ok)

      expect(response.body).to include(I18n.t!("tags.edit.description"))
      expect(response.body).to include(tag_name)
    end

    it "returns service unavailable when the Publishing API is down" do
      stub_publishing_api_isnt_available

      get tags_path(edition.document)

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include(I18n.t!("tags.edit.api_down"))
    end

    it "shows a warning when editing the primary organisation tag of an access limited edition" do
      tag_field = build(:tag_field,
                        type: "single_tag",
                        id: "primary_publishing_organisation",
                        document_type: "organisation")
      document_type = build(:document_type, tags: [tag_field])
      edition = create(:edition,
                       :access_limited,
                       document_type_id: document_type.id,
                       created_by: current_user)
      stub_publishing_api_has_linkables(
        [{ "content_id" => current_user.organisation_content_id,
           "internal_name" => "Organisation" }],
        document_type: tag_field.document_type,
      )

      get tags_path(edition.document)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t!("tags.edit.organisation_warning"))
    end
  end

  describe "PATCH /documents/:document/tags" do
    before { stub_any_publishing_api_put_content }

    it "redirects to document path on successful request" do
      tag_field = build(:tag_field, type: "multi_tag", id: "field")
      document_type = build(:document_type, tags: [tag_field])
      edition = create(:edition, document_type_id: document_type.id)

      patch tags_path(edition.document),
            params: { tags: { field: [SecureRandom.uuid] } }

      expect(response).to redirect_to(document_path(edition.document))
    end

    it "returns an issue and unprocessable response when a primary publishing "\
       "organisation is not selected" do
      tag_field = build(:tag_field,
                        type: "single_tag",
                        id: "primary_publishing_organisation",
                        document_type: "organisation")
      document_type = build(:document_type, tags: [tag_field])
      edition = create(:edition, document_type_id: document_type.id)
      stub_publishing_api_has_linkables(
        [{ "content_id" => SecureRandom.uuid, "internal_name" => "Organisation" }],
        document_type: tag_field.document_type,
      )

      patch tags_path(edition.document), params: { tags: {} }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(
        I18n.t!("requirements.primary_publishing_organisation.blank.form_message"),
      )
    end
  end
end