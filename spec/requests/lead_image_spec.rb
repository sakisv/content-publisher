RSpec.describe "Lead Image" do
  describe "POST /documents/:document/lead-image/:image_id" do
    let(:image_revision) { create(:image_revision) }
    let(:document_type) { build(:document_type, :with_lead_image) }

    it_behaves_like "requests that assert edition state",
                    "choosing lead image for a non editable edition",
                    routes: { choose_lead_image_path: %i[post] } do
      let(:edition) { create(:edition, :published) }
      let(:route_params) { [edition.document, "image_id"] }
    end

    it_behaves_like "requests that return status",
                    "choosing lead image when not supported",
                    status: :not_found,
                    routes: { choose_lead_image_path: %i[post] } do
      let(:edition) { create(:edition) }
      let(:route_params) { [edition.document, "image_id"] }
    end

    it "redirects to document summary with an alert" do
      edition = create(:edition,
                       document_type: document_type,
                       image_revisions: [image_revision])
      post choose_lead_image_path(edition.document, image_revision.image_id)

      expect(response).to redirect_to(document_path(edition.document))
      follow_redirect!
      expect(response.body).to have_content(
        I18n.t!("documents.show.flashes.lead_image.selected",
                file: image_revision.filename),
      )
    end

    it "returns a 404 if the image revision isn't associated with the edition" do
      edition = create(:edition, document_type: document_type)
      post choose_lead_image_path(edition.document, image_revision.image_id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /documents/:document/lead-image" do
    let(:document_type) { build(:document_type, :with_lead_image) }

    it_behaves_like "requests that assert edition state",
                    "removing lead image for a non editable edition",
                    routes: { remove_lead_image_path: %i[delete] } do
      let(:edition) { create(:edition, :published) }
    end

    it_behaves_like "requests that return status",
                    "choosing lead image when not supported",
                    status: :not_found,
                    routes: { remove_lead_image_path: %i[post] } do
      let(:edition) { create(:edition) }
      let(:route_params) { [edition.document, "image_id"] }
    end

    it "redirects with an alert when an edition has a lead image" do
      image_revision = create(:image_revision)
      edition = create(:edition,
                       document_type: document_type,
                       lead_image_revision: image_revision)
      delete remove_lead_image_path(edition.document)

      expect(response).to redirect_to(images_path(edition.document))
      follow_redirect!
      alert = I18n.t!("images.index.flashes.lead_image.removed",
                      file: image_revision.filename)
      expect(response.body).to have_selector(".gem-c-success-alert", text: alert)
    end

    it "redirects without an alert when an edition doesn't have a lead image" do
      edition = create(:edition, document_type: document_type)
      delete remove_lead_image_path(edition.document)

      expect(response).to redirect_to(images_path(edition.document))
      follow_redirect!
      expect(response.body).not_to have_selector(".gem-c-success-alert")
    end
  end
end
