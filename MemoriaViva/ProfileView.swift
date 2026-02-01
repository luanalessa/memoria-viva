import SwiftUI

// MARK: - ProfileView (single file)
struct ProfileView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {

                ProfileHeader()

                InfoCard(
                    icon: "heart",
                    title: "O que é o Memória Viva",
                    content: "O Memória Viva é uma plataforma que conecta moradores e visitantes às histórias, tradições e eventos culturais das cidades brasileiras. Através de um mapa interativo e uma agenda colaborativa, preservamos a memória afetiva dos territórios."
                )

                SupportSection()

                ContributionSection()

                ContactSection()

                FooterSection()
            }
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Header
private struct ProfileHeader: View {
    var body: some View {
        VStack(spacing: 10) {

            // Troque "mv_icon" pelo nome do asset do seu ícone
            Image("memoriaVivaLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 6)

            Text("Memória Viva")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Preservando memórias, conectando pessoas")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 6)
    }
}

// MARK: - Generic Card
private struct InfoCard: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        MVSectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    MVSectionIcon(systemName: icon, tint: Color(.systemOrange))
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Quem apoia
private struct SupportSection: View {
    var body: some View {
        MVSectionCard {
            VStack(alignment: .leading, spacing: 12) {
                MVSectionTitle(systemName: "person.2", title: "Quem apoia", tint: Color(.systemOrange))

                VStack(spacing: 10) {
                    SupportItem(
                        initials: "PM",
                        title: "Prefeitura Municipal",
                        subtitle: "Secretaria de Cultura"
                    )
                    
                }
            }
        }
    }
}

private struct SupportItem: View {
    let initials: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Text(initials)
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Como contribuir
private struct ContributionSection: View {
    var body: some View {
        MVSectionCard {
            VStack(alignment: .leading, spacing: 14) {
                MVSectionTitle(systemName: "", title: "Como contribuir", tint: Color(.systemOrange))

                ContributionItem(
                    number: "1",
                    title: "Envie histórias",
                    description: "compartilhe memórias e tradições da sua cidade",
                    tint: Color(.systemOrange)
                )

                ContributionItem(
                    number: "2",
                    title: "Divulgue eventos",
                    description: "ajude a promover a cultura local",
                    tint: Color(.systemYellow)
                )

                ContributionItem(
                    number: "3",
                    title: "Apoie o comércio",
                    description: "valorize negócios que fortalecem a cultura",
                    tint: Color(.systemGreen)
                )
            }
        }
    }
}

private struct ContributionItem: View {
    let number: String
    let title: String
    let description: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Contato
private struct ContactSection: View {
    private let email = "contato@memoriaviva.app"

    var body: some View {
        MVSectionCard {
            VStack(alignment: .leading, spacing: 12) {
                MVSectionTitle(systemName: "envelope", title: "Contato", tint: Color(.systemOrange))

                HStack(spacing: 12) {
                    Text(email)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)

                    Button {
                        openMail(to: email)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Enviar e-mail")
                }
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func openMail(to email: String) {
        guard let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Footer
private struct FooterSection: View {
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                Button("Termos de uso") {
                    // TODO: navegar para Termos
                }
                .font(.footnote)
                .foregroundColor(.secondary)

                Button("Privacidade") {
                    // TODO: navegar para Privacidade
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }

            Text("Versão 1.0.0 • Feito com ❤️ no Ceará")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 6)
    }
}

// MARK: - UI Helpers (style)
private struct MVSectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
            .padding(.horizontal, 16)
    }
}

private struct MVSectionTitle: View {
    let systemName: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            MVSectionIcon(systemName: systemName, tint: tint)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

private struct MVSectionIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
