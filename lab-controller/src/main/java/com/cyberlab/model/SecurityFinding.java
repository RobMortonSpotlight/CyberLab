package com.cyberlab.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "security_findings")
public class SecurityFinding {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String findingId;

    @Column(nullable = false)
    private String title;

    private String description;

    @Column(nullable = false)
    private String targetName;

    private String service;

    @Enumerated(EnumType.STRING)
    private Difficulty difficulty;

    private String learningObjective;

    @Column(columnDefinition = "TEXT")
    private String discoveryMethod;

    @Column(columnDefinition = "TEXT")
    private String expectedEvidence;

    private String prerequisiteFinding;

    private String suggestedMentorQuestion;

    private Boolean isActive;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        isActive = true;
    }

    public enum Difficulty {
        INTRODUCTORY,
        INTERMEDIATE,
        ADVANCED
    }

    // Constructors
    public SecurityFinding() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getFindingId() { return findingId; }
    public void setFindingId(String findingId) { this.findingId = findingId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getTargetName() { return targetName; }
    public void setTargetName(String targetName) { this.targetName = targetName; }
    public String getService() { return service; }
    public void setService(String service) { this.service = service; }
    public Difficulty getDifficulty() { return difficulty; }
    public void setDifficulty(Difficulty difficulty) { this.difficulty = difficulty; }
    public String getLearningObjective() { return learningObjective; }
    public void setLearningObjective(String learningObjective) { this.learningObjective = learningObjective; }
    public String getDiscoveryMethod() { return discoveryMethod; }
    public void setDiscoveryMethod(String discoveryMethod) { this.discoveryMethod = discoveryMethod; }
    public String getExpectedEvidence() { return expectedEvidence; }
    public void setExpectedEvidence(String expectedEvidence) { this.expectedEvidence = expectedEvidence; }
    public String getPrerequisiteFinding() { return prerequisiteFinding; }
    public void setPrerequisiteFinding(String prerequisiteFinding) { this.prerequisiteFinding = prerequisiteFinding; }
    public String getSuggestedMentorQuestion() { return suggestedMentorQuestion; }
    public void setSuggestedMentorQuestion(String suggestedMentorQuestion) { this.suggestedMentorQuestion = suggestedMentorQuestion; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
