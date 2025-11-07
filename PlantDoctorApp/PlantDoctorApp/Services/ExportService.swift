//
//  ExportService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation
import UIKit
import PDFKit

class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - PDF Export

    func exportToPDF(record: PlantRecord, image: UIImage?) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Plant Doctor App",
            kCGPDFContextAuthor: "Plant Doctor",
            kCGPDFContextTitle: "Plant Analysis Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("PlantReport_\(record.id.uuidString).pdf")

        do {
            try renderer.writePDF(to: pdfURL) { context in
                context.beginPage()

                var currentY: CGFloat = 40

                // Title
                let titleFont = UIFont.boldSystemFont(ofSize: 24)
                let titleText = "Plant Analysis Report"
                let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
                let titleSize = titleText.size(withAttributes: titleAttributes)
                let titleRect = CGRect(x: 40, y: currentY, width: pageWidth - 80, height: titleSize.height)
                titleText.draw(in: titleRect, withAttributes: titleAttributes)
                currentY += titleSize.height + 20

                // Date
                let dateFont = UIFont.systemFont(ofSize: 12)
                let dateText = "Date: \(record.formattedDate)"
                let dateAttributes: [NSAttributedString.Key: Any] = [.font: dateFont, .foregroundColor: UIColor.gray]
                let dateSize = dateText.size(withAttributes: dateAttributes)
                let dateRect = CGRect(x: 40, y: currentY, width: pageWidth - 80, height: dateSize.height)
                dateText.draw(in: dateRect, withAttributes: dateAttributes)
                currentY += dateSize.height + 20

                // Image
                if let image = image {
                    let imageHeight: CGFloat = 200
                    let imageWidth = (pageWidth - 80)
                    let imageRect = CGRect(x: 40, y: currentY, width: imageWidth, height: imageHeight)
                    image.draw(in: imageRect)
                    currentY += imageHeight + 20
                }

                // Plant Identification
                if let identification = record.plantIdentification {
                    currentY = drawSection(title: "Plant Identification", y: currentY, pageWidth: pageWidth, context: context)
                    currentY = drawText("Common Name: \(identification.commonName)", y: currentY, pageWidth: pageWidth)
                    currentY = drawText("Scientific Name: \(identification.scientificName)", y: currentY, pageWidth: pageWidth)
                    currentY = drawText("Family: \(identification.family)", y: currentY, pageWidth: pageWidth)
                    currentY += 10
                }

                // Health Status
                currentY = drawSection(title: "Health Status", y: currentY, pageWidth: pageWidth, context: context)
                let status = record.analysisResult.isHealthy ? "Healthy ✓" : "Issues Detected ⚠️"
                currentY = drawText("Status: \(status)", y: currentY, pageWidth: pageWidth)
                currentY += 10

                // Diagnosis
                currentY = drawSection(title: "Diagnosis", y: currentY, pageWidth: pageWidth, context: context)
                currentY = drawText(record.analysisResult.diagnosis, y: currentY, pageWidth: pageWidth)
                currentY += 10

                // Problems
                if !record.analysisResult.problems.isEmpty {
                    currentY = drawSection(title: "Problems Found", y: currentY, pageWidth: pageWidth, context: context)
                    for problem in record.analysisResult.problems {
                        currentY = drawText("• \(problem)", y: currentY, pageWidth: pageWidth)
                    }
                    currentY += 10
                }

                // Treatment
                currentY = drawSection(title: "Treatment Recommendations", y: currentY, pageWidth: pageWidth, context: context)
                currentY = drawText(record.analysisResult.treatment, y: currentY, pageWidth: pageWidth)
                currentY += 10

                // Confidence
                currentY = drawText("Confidence Level: \(record.analysisResult.confidenceLevel)", y: currentY, pageWidth: pageWidth, fontSize: 10, color: .gray)
            }

            return pdfURL
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }

    private func drawSection(title: String, y: CGFloat, pageWidth: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let font = UIFont.boldSystemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = title.size(withAttributes: attributes)
        let rect = CGRect(x: 40, y: y, width: pageWidth - 80, height: size.height)
        title.draw(in: rect, withAttributes: attributes)
        return y + size.height + 8
    }

    private func drawText(_ text: String, y: CGFloat, pageWidth: CGFloat, fontSize: CGFloat = 12, color: UIColor = .black) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let boundingRect = text.boundingRect(with: CGSize(width: pageWidth - 80, height: .greatestFiniteMagnitude),
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             attributes: attributes,
                                             context: nil)
        let rect = CGRect(x: 40, y: y, width: pageWidth - 80, height: boundingRect.height)
        text.draw(in: rect, withAttributes: attributes)
        return y + boundingRect.height + 5
    }

    // MARK: - CSV Export

    func exportHistoryToCSV(records: [PlantRecord]) -> URL? {
        var csvText = "Date,Plant Name,Species,Health Status,Diagnosis,Problems,Treatment,Confidence\n"

        for record in records {
            let date = record.formattedDate.replacingOccurrences(of: ",", with: ";")
            let plantName = (record.plantName ?? "Unknown").replacingOccurrences(of: ",", with: ";")
            let species = (record.plantIdentification?.scientificName ?? "N/A").replacingOccurrences(of: ",", with: ";")
            let healthStatus = record.analysisResult.isHealthy ? "Healthy" : "Issues Detected"
            let diagnosis = record.analysisResult.diagnosis.replacingOccurrences(of: ",", with: ";")
            let problems = record.analysisResult.problems.joined(separator: "; ")
            let treatment = record.analysisResult.treatment.replacingOccurrences(of: ",", with: ";")
            let confidence = record.analysisResult.confidenceLevel

            let row = "\(date),\(plantName),\(species),\(healthStatus),\(diagnosis),\(problems),\(treatment),\(confidence)\n"
            csvText.append(row)
        }

        let csvURL = FileManager.default.temporaryDirectory.appendingPathComponent("PlantHistory_\(Date().timeIntervalSince1970).csv")

        do {
            try csvText.write(to: csvURL, atomically: true, encoding: .utf8)
            return csvURL
        } catch {
            print("Error creating CSV: \(error)")
            return nil
        }
    }
}
