RSpec.describe "components/_attachment_meta" do
  it "can include attribute metadata" do
    render template: described_template,
           locals: { attachment: { content_type: "application/pdf",
                                   file_size: 2048,
                                   number_of_pages: 2 } }
    expect(rendered)
      .to have_selector("abbr.app-c-attachment-meta__abbr[title='Portable Document Format']", text: "PDF")
      .and match(/2 KB/)
      .and match(/2 pages/)
  end

  it "can show file type that doesn't have an abbreviation" do
    render template: described_template,
           locals: { attachment: { content_type: "text/plain" } }
    expect(rendered).to match(/Plain Text/)
  end

  it "doesn't show metadata information when there isn't any to show" do
    render template: described_template,
           locals: { attachment: { content_type: "unknown/type" } }
    expect(rendered).not_to have_selector(".app-c-attachment-meta__metadata")
  end

  it "shows reference details on the first metadata line if provided" do
    render template: described_template,
           locals: { attachment: { filename: "register.csv",
                                   content_type: "application/pdf",
                                   file_size: 20_000,
                                   number_of_pages: 7,
                                   isbn: "978-1-5286-1173-2",
                                   unique_reference: "2259",
                                   command_paper_number: "Cd. 67" } }
    expect(rendered).to have_selector(".app-c-attachment-meta__metadata",
                                      text: "Ref: ISBN 978-1-5286-1173-2, 2259, Cd. 67")
  end

  it "shows unnumbered details on the second metadata line if marked so" do
    render template: described_template,
           locals: { attachment: { filename: "register.csv",
                                   content_type: "application/pdf",
                                   file_size: 20_000,
                                   number_of_pages: 7,
                                   isbn: "978-1-5286-1173-2",
                                   unique_reference: "2259",
                                   unnumbered_command_paper: true } }
    expect(rendered).to have_selector(".app-c-attachment-meta__metadata",
                                      text: "Unnumbered command paper")
  end
end
