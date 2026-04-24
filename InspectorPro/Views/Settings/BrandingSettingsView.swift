import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct BrandingSettingsContainerView: View {
    private enum LoadState {
        case loading
        case loaded(BrandingProfile)
        case failed
    }

    @Environment(\.modelContext) private var modelContext
    @State private var loadState: LoadState = .loading

    var body: some View {
        Group {
            switch loadState {
            case .loaded(let brandingProfile):
                BrandingSettingsView(brandingProfile: brandingProfile)
            case .loading:
                ProgressView(AppStrings.text("טוען..."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: AppStrings.text("לא ניתן לטעון את הגדרות המיתוג"),
                    subtitle: AppStrings.text("נסה שוב מאוחר יותר")
                )
                .padding()
            }
        }
        .task {
            await loadBrandingProfileIfNeeded()
        }
        .navigationTitle(AppStrings.text("מיתוג חברה"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func loadBrandingProfileIfNeeded() async {
        guard case .loading = loadState else { return }

        do {
            let brandingProfile = try BrandingBootstrapper.fetchOrCreateDefaultBrandingProfile(in: modelContext)
            loadState = .loaded(brandingProfile)
        } catch {
            loadState = .failed
        }
    }
}

struct BrandingLogoThumbnail: View {
    let brandingProfile: BrandingProfile?
    var size: CGFloat = 44

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .background(Color(.secondarySystemBackground))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        image = BrandingAssetStorage.displayLogoImage(for: brandingProfile)
    }
}

private struct BrandingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.layoutDirection) private var layoutDirection

    let brandingProfile: BrandingProfile

    @State private var companyName = ""
    @State private var footerAddressLine = ""
    @State private var primaryFooterFields = BrandingPrimaryFooterFields()
    @State private var secondaryFooterFields = BrandingSecondaryFooterFields()
    @State private var usesBundledDefaultLogo = true
    @State private var showLogoInReport = true
    @State private var showFooterInReport = true
    @State private var showsSecondaryContactFields = false
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var logoPreviewImage: UIImage?
    @State private var pendingCustomLogoImage: UIImage?
    @State private var initialPrimaryFooterFields = BrandingPrimaryFooterFields()
    @State private var initialSecondaryFooterFields = BrandingSecondaryFooterFields()
    @State private var initialized = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var textAlignment: TextAlignment {
        AppTextDirection.textAlignment(for: layoutDirection)
    }

    private var isFormValid: Bool {
        !normalized(companyName).isEmpty
    }

    var body: some View {
        Form {
            Section(AppStrings.text("פרטי חברה")) {
                TextField(AppStrings.text("שם החברה"), text: $companyName)
                    .multilineTextAlignment(textAlignment)
            }

            Section(AppStrings.text("לוגו")) {
                Toggle(AppStrings.text("הצג לוגו בדוח"), isOn: $showLogoInReport)

                HStack {
                    Spacer()
                    BrandingLogoPreview(image: logoPreviewImage)
                    Spacer()
                }
                .listRowBackground(Color.clear)

                PhotosPicker(
                    selection: $selectedLogoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(AppStrings.text("בחר לוגו מהספריה"), systemImage: "photo.on.rectangle")
                }

                if !usesBundledDefaultLogo {
                    Button(AppStrings.text("השתמש בלוגו ברירת מחדל")) {
                        restoreBundledLogo()
                    }
                }
            }

            Section(AppStrings.text("כותרת תחתונה")) {
                Toggle(AppStrings.text("הצג כותרת בדוח"), isOn: $showFooterInReport)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(AppStrings.text("שורת כתובת תחתונה"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    DirectionalTextField(
                        text: $footerAddressLine,
                        placeholder: AppStrings.text("שורת כתובת תחתונה"),
                        layoutDirection: layoutDirection
                    )
                    .frame(height: 22)
                }

                BrandingFooterFieldsSection(
                    title: AppStrings.text("שורת קשר ראשית"),
                    firstLeadingTitle: AppStrings.text("שם"),
                    firstTrailingTitle: AppStrings.text("תפקיד / תווית"),
                    secondLeadingTitle: AppStrings.text("טלפון"),
                    secondTrailingTitle: AppStrings.text("דוא\"ל"),
                    firstLeadingValue: $primaryFooterFields.contactName,
                    firstTrailingValue: $primaryFooterFields.roleLabel,
                    secondLeadingValue: $primaryFooterFields.phoneNumber,
                    secondTrailingValue: $primaryFooterFields.emailAddress,
                    firstLeadingLayoutDirection: layoutDirection,
                    firstTrailingLayoutDirection: layoutDirection,
                    secondLeadingLayoutDirection: .leftToRight,
                    secondTrailingLayoutDirection: .leftToRight,
                    secondLeadingKeyboardType: .phonePad,
                    secondTrailingKeyboardType: .emailAddress,
                    secondTrailingAutocapitalizationType: .none,
                    secondTrailingTextContentType: .emailAddress,
                    secondTrailingAutocorrectionType: .no
                )

                if showsSecondaryContactFields {
                    BrandingFooterFieldsSection(
                        title: AppStrings.text("שורת קשר משנית"),
                        firstLeadingTitle: AppStrings.text("שם / תווית"),
                        firstTrailingTitle: AppStrings.text("מספר"),
                        secondLeadingTitle: AppStrings.text("תווית נוספת"),
                        secondTrailingTitle: AppStrings.text("מספר נוסף"),
                        firstLeadingValue: $secondaryFooterFields.firstLabel,
                        firstTrailingValue: $secondaryFooterFields.firstNumber,
                        secondLeadingValue: $secondaryFooterFields.secondLabel,
                        secondTrailingValue: $secondaryFooterFields.secondNumber,
                        firstLeadingLayoutDirection: layoutDirection,
                        firstTrailingLayoutDirection: .leftToRight,
                        secondLeadingLayoutDirection: layoutDirection,
                        secondTrailingLayoutDirection: .leftToRight,
                        firstTrailingKeyboardType: .phonePad,
                        firstTrailingTextContentType: .telephoneNumber,
                        secondTrailingKeyboardType: .phonePad,
                        secondTrailingTextContentType: .telephoneNumber
                    )

                    Button(AppStrings.text("הסר פרטי קשר נוספים")) {
                        clearSecondaryFooterFields()
                    }
                    .font(.footnote)
                } else {
                    Button(AppStrings.text("+ הוסף פרטי קשר נוספים")) {
                        showsSecondaryContactFields = true
                    }
                    .font(.footnote)
                }
            }
        }
        .onAppear(perform: loadInitialStateIfNeeded)
        .onChange(of: selectedLogoItem) { _, newItem in
            Task {
                await loadSelectedLogo(from: newItem)
            }
        }
        .alert(AppStrings.text("שמירה נכשלה"), isPresented: errorAlertPresented) {
            Button(AppStrings.text("אישור"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? AppStrings.text("אירעה שגיאה בשמירה"))
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppStrings.text("שמור")) {
                    saveBranding()
                }
                .disabled(!isFormValid || isSaving)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.text("סגור")) {
                    dismiss()
                }
            }
        }
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func loadInitialStateIfNeeded() {
        guard !initialized else { return }
        initialized = true
        companyName = brandingProfile.name
        footerAddressLine = BrandingFooterFormatter.strippingDirectionalMarks(from: brandingProfile.footerAddressLine)
        primaryFooterFields = BrandingPrimaryFooterFields.fromStoredLines(
            pdf: brandingProfile.primaryFooterLinePDF,
            docx: brandingProfile.primaryFooterLineDOCX
        )
        initialPrimaryFooterFields = primaryFooterFields
        secondaryFooterFields = BrandingSecondaryFooterFields.fromStoredLine(brandingProfile.secondaryFooterLine)
        initialSecondaryFooterFields = secondaryFooterFields
        usesBundledDefaultLogo = brandingProfile.usesBundledDefaultLogo
        showLogoInReport = brandingProfile.showLogoInReport
        showFooterInReport = brandingProfile.showFooterInReport
        showsSecondaryContactFields = secondaryFooterFields.hasAnyValue
        logoPreviewImage = BrandingAssetStorage.displayLogoImage(for: brandingProfile)
    }

    @MainActor
    private func loadSelectedLogo(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = AppStrings.text("לא ניתן לטעון תמונה")
                return
            }

            pendingCustomLogoImage = image
            logoPreviewImage = image
            usesBundledDefaultLogo = false
        } catch {
            errorMessage = AppStrings.text("לא ניתן לטעון תמונה")
        }
    }

    private func restoreBundledLogo() {
        selectedLogoItem = nil
        pendingCustomLogoImage = nil
        usesBundledDefaultLogo = true
        logoPreviewImage = BrandingAssetStorage.displayLogoImage(for: nil)
    }

    private func saveBranding() {
        let normalizedCompanyName = normalized(companyName)
        let normalizedFooterAddressLine = BrandingFooterFormatter.normalizeAddressLine(normalized(footerAddressLine))
        let normalizedPrimaryFooterFields = BrandingPrimaryFooterFields(
            contactName: normalized(primaryFooterFields.contactName),
            roleLabel: normalized(primaryFooterFields.roleLabel),
            phoneNumber: normalized(primaryFooterFields.phoneNumber),
            emailAddress: normalized(primaryFooterFields.emailAddress)
        )
        let normalizedSecondaryFooterFields = BrandingSecondaryFooterFields(
            firstLabel: normalized(secondaryFooterFields.firstLabel),
            firstNumber: normalized(secondaryFooterFields.firstNumber),
            secondLabel: normalized(secondaryFooterFields.secondLabel),
            secondNumber: normalized(secondaryFooterFields.secondNumber)
        )

        guard !normalizedCompanyName.isEmpty else {
            return
        }

        isSaving = true

        do {
            brandingProfile.name = normalizedCompanyName
            brandingProfile.footerAddressLine = normalizedFooterAddressLine
            brandingProfile.showLogoInReport = showLogoInReport
            brandingProfile.showFooterInReport = showFooterInReport

            if normalizedPrimaryFooterFields != initialPrimaryFooterFields {
                let normalizedPrimaryLine = BrandingFooterFormatter.composePrimaryLine(normalizedPrimaryFooterFields)
                brandingProfile.primaryFooterLinePDF = normalizedPrimaryLine
                brandingProfile.primaryFooterLineDOCX = normalizedPrimaryLine
            }

            if normalizedSecondaryFooterFields != initialSecondaryFooterFields {
                brandingProfile.secondaryFooterLine = BrandingFooterFormatter.composeSecondaryLine(normalizedSecondaryFooterFields)
            }

            if usesBundledDefaultLogo {
                BrandingAssetStorage.deleteCustomLogo(for: brandingProfile)
                brandingProfile.usesBundledDefaultLogo = true
            } else {
                if let pendingCustomLogoImage {
                    try BrandingAssetStorage.saveCustomLogo(pendingCustomLogoImage, for: brandingProfile)
                    self.pendingCustomLogoImage = nil
                }
                brandingProfile.usesBundledDefaultLogo = false
            }

            try modelContext.save()
            initialPrimaryFooterFields = normalizedPrimaryFooterFields
            initialSecondaryFooterFields = normalizedSecondaryFooterFields
            dismiss()
        } catch {
            errorMessage = AppStrings.text("אירעה שגיאה בשמירה")
        }

        isSaving = false
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearSecondaryFooterFields() {
        secondaryFooterFields = BrandingSecondaryFooterFields()
        showsSecondaryContactFields = false
    }
}

private struct BrandingFooterFieldsSection: View {
    let title: String
    let firstLeadingTitle: String
    let firstTrailingTitle: String
    let secondLeadingTitle: String
    let secondTrailingTitle: String
    @Binding var firstLeadingValue: String
    @Binding var firstTrailingValue: String
    @Binding var secondLeadingValue: String
    @Binding var secondTrailingValue: String
    let firstLeadingLayoutDirection: LayoutDirection
    let firstTrailingLayoutDirection: LayoutDirection
    let secondLeadingLayoutDirection: LayoutDirection
    let secondTrailingLayoutDirection: LayoutDirection
    var firstTrailingKeyboardType: UIKeyboardType = .default
    var firstTrailingAutocapitalizationType: UITextAutocapitalizationType = .sentences
    var firstTrailingTextContentType: UITextContentType?
    var firstTrailingAutocorrectionType: UITextAutocorrectionType = .default
    var secondLeadingKeyboardType: UIKeyboardType = .default
    var secondLeadingAutocapitalizationType: UITextAutocapitalizationType = .sentences
    var secondLeadingTextContentType: UITextContentType?
    var secondLeadingAutocorrectionType: UITextAutocorrectionType = .default
    var secondTrailingKeyboardType: UIKeyboardType = .default
    var secondTrailingAutocapitalizationType: UITextAutocapitalizationType = .sentences
    var secondTrailingTextContentType: UITextContentType?
    var secondTrailingAutocorrectionType: UITextAutocorrectionType = .default

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 12) {
                CompactLTRTextField(
                    title: firstTrailingTitle,
                    text: $firstTrailingValue,
                    layoutDirection: firstTrailingLayoutDirection,
                    keyboardType: firstTrailingKeyboardType,
                    autocapitalizationType: firstTrailingAutocapitalizationType,
                    textContentType: firstTrailingTextContentType,
                    autocorrectionType: firstTrailingAutocorrectionType
                )

                CompactInputField(
                    title: firstLeadingTitle,
                    text: $firstLeadingValue,
                    layoutDirection: firstLeadingLayoutDirection
                )
            }

            HStack(spacing: 12) {
                CompactLTRTextField(
                    title: secondTrailingTitle,
                    text: $secondTrailingValue,
                    layoutDirection: secondTrailingLayoutDirection,
                    keyboardType: secondTrailingKeyboardType,
                    autocapitalizationType: secondTrailingAutocapitalizationType,
                    textContentType: secondTrailingTextContentType,
                    autocorrectionType: secondTrailingAutocorrectionType
                )

                CompactInputField(
                    title: secondLeadingTitle,
                    text: $secondLeadingValue,
                    layoutDirection: secondLeadingLayoutDirection,
                    keyboardType: secondLeadingKeyboardType,
                    autocapitalizationType: secondLeadingAutocapitalizationType,
                    textContentType: secondLeadingTextContentType,
                    autocorrectionType: secondLeadingAutocorrectionType
                )
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CompactLTRTextField: View {
    let title: String
    @Binding var text: String
    let layoutDirection: LayoutDirection
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textContentType: UITextContentType?
    var autocorrectionType: UITextAutocorrectionType = .default

    var body: some View {
        CompactInputField(
            title: title,
            text: $text,
            layoutDirection: layoutDirection,
            keyboardType: keyboardType,
            autocapitalizationType: autocapitalizationType,
            textContentType: textContentType,
            autocorrectionType: autocorrectionType
        )
    }
}

private struct CompactInputField: View {
    let title: String
    @Binding var text: String
    let layoutDirection: LayoutDirection
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textContentType: UITextContentType?
    var autocorrectionType: UITextAutocorrectionType = .default

    var body: some View {
        VStack(alignment: layoutDirection == .rightToLeft ? .trailing : .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: layoutDirection == .rightToLeft ? .trailing : .leading)

            DirectionalTextField(
                text: $text,
                placeholder: title,
                layoutDirection: layoutDirection,
                keyboardType: keyboardType,
                autocapitalizationType: autocapitalizationType,
                textContentType: textContentType,
                autocorrectionType: autocorrectionType
            )
            .frame(height: 22)
        }
        .frame(maxWidth: .infinity, alignment: layoutDirection == .rightToLeft ? .trailing : .leading)
    }
}

private struct BrandingLogoPreview: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground))
            }
        }
        .frame(width: 140, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
