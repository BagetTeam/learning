from datetime import date, timedelta

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.accounts.models import CustomUser, Employer, JobSeeker
from apps.jobs.models import Application, Category, Job


CATEGORY_DEFINITIONS = [
    {"name": "Engineering", "icon": "fas fa-code"},
    {"name": "Design", "icon": "fas fa-paint-brush"},
    {"name": "Product", "icon": "fas fa-lightbulb"},
    {"name": "Marketing", "icon": "fas fa-bullhorn"},
]

EMPLOYER_DEFINITIONS = [
    {
        "username": "employer_acme",
        "email": "hiring@acme.example",
        "company_name": "Acme Analytics",
        "company_description": "Data platform company focused on observability and analytics.",
        "company_website": "https://acme.example",
        "location": "Remote",
        "phone": "+1-555-0101",
        "industry": "Software",
    },
    {
        "username": "employer_northstar",
        "email": "jobs@northstar.example",
        "company_name": "Northstar Commerce",
        "company_description": "E-commerce enablement tools for SMBs.",
        "company_website": "https://northstar.example",
        "location": "Berlin",
        "phone": "+49-30-555-0102",
        "industry": "E-commerce",
    },
]

JOB_SEEKER_DEFINITIONS = [
    {
        "username": "alice_seeker",
        "email": "alice@example.com",
        "skills": "Python, Django, REST APIs",
        "experience": "3 years building web applications",
        "education": "B.Sc. Computer Science",
    },
    {
        "username": "bob_seeker",
        "email": "bob@example.com",
        "skills": "React, TypeScript, UX",
        "experience": "4 years in frontend engineering",
        "education": "B.Des. Interaction Design",
    },
    {
        "username": "carol_seeker",
        "email": "carol@example.com",
        "skills": "SEO, Content Strategy, Analytics",
        "experience": "5 years in growth marketing",
        "education": "MBA",
    },
]

JOB_DEFINITIONS = [
    {
        "key": "backend_engineer",
        "title": "Backend Engineer",
        "employer_username": "employer_acme",
        "category_name": "Engineering",
        "description": "Build and maintain scalable backend services for analytics workloads.",
        "requirements": "2+ years Python, Django, SQL, and cloud fundamentals.",
        "location": "Remote",
        "salary": "$95,000 - $120,000",
        "job_type": "full_time",
        "deadline_in_days": 45,
    },
    {
        "key": "product_designer",
        "title": "Product Designer",
        "employer_username": "employer_northstar",
        "category_name": "Design",
        "description": "Own product UI/UX from discovery to delivery across web surfaces.",
        "requirements": "Portfolio demonstrating end-to-end product design process.",
        "location": "Berlin",
        "salary": "€60,000 - €78,000",
        "job_type": "full_time",
        "deadline_in_days": 30,
    },
    {
        "key": "growth_marketer",
        "title": "Growth Marketer",
        "employer_username": "employer_northstar",
        "category_name": "Marketing",
        "description": "Drive acquisition through SEO, paid channels, and experimentation.",
        "requirements": "Experience with analytics tools and multi-channel campaigns.",
        "location": "Hybrid",
        "salary": "€52,000 - €68,000",
        "job_type": "contract",
        "deadline_in_days": 60,
    },
]

APPLICATION_DEFINITIONS = [
    {
        "job_key": "backend_engineer",
        "job_seeker_username": "alice_seeker",
        "status": "reviewing",
        "cover_letter": "I have built multiple Django APIs with performance and test coverage in mind.",
    },
    {
        "job_key": "product_designer",
        "job_seeker_username": "bob_seeker",
        "status": "pending",
        "cover_letter": "I focus on measurable UX outcomes and close collaboration with engineering.",
    },
    {
        "job_key": "growth_marketer",
        "job_seeker_username": "carol_seeker",
        "status": "accepted",
        "cover_letter": "I have consistently improved CAC and conversion in my recent roles.",
    },
]


class Command(BaseCommand):
    help = "Create deterministic demo data for the job portal."

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete previously seeded domain data (non-superuser accounts) before seeding.",
        )
        parser.add_argument(
            "--password",
            default="DemoPass123!",
            help="Password applied to all seeded users.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        reset = options["reset"]
        password = options["password"]

        if reset:
            self.stdout.write("Reset flag provided. Clearing existing domain data...")
            Application.objects.all().delete()
            Job.objects.all().delete()
            Category.objects.all().delete()
            Employer.objects.all().delete()
            JobSeeker.objects.all().delete()
            CustomUser.objects.filter(is_superuser=False).delete()

        categories = self._seed_categories()
        employers = self._seed_employers(password)
        job_seekers = self._seed_job_seekers(password)
        jobs = self._seed_jobs(categories, employers)
        self._seed_applications(jobs, job_seekers)

        self.stdout.write(self.style.SUCCESS("Demo data seeded successfully."))
        self.stdout.write(
            f"Users: {CustomUser.objects.filter(is_superuser=False).count()} | "
            f"Employers: {Employer.objects.count()} | "
            f"Job seekers: {JobSeeker.objects.count()} | "
            f"Categories: {Category.objects.count()} | "
            f"Jobs: {Job.objects.count()} | "
            f"Applications: {Application.objects.count()}"
        )
        self.stdout.write("All seeded users share password: (value from --password, default: DemoPass123!)")

    def _seed_categories(self):
        categories = {}
        for item in CATEGORY_DEFINITIONS:
            category, _ = Category.objects.update_or_create(
                name=item["name"],
                defaults={"icon": item["icon"]},
            )
            categories[item["name"]] = category
        return categories

    def _seed_employers(self, password):
        employers = {}
        for item in EMPLOYER_DEFINITIONS:
            user, _ = CustomUser.objects.update_or_create(
                username=item["username"],
                defaults={
                    "email": item["email"],
                    "is_employer": True,
                    "is_job_seeker": False,
                    "is_active": True,
                },
            )
            user.set_password(password)
            user.save(update_fields=["password"])

            employer, _ = Employer.objects.update_or_create(
                user=user,
                defaults={
                    "company_name": item["company_name"],
                    "company_description": item["company_description"],
                    "company_website": item["company_website"],
                    "location": item["location"],
                    "phone": item["phone"],
                    "industry": item["industry"],
                },
            )
            employers[item["username"]] = employer
        return employers

    def _seed_job_seekers(self, password):
        job_seekers = {}
        for item in JOB_SEEKER_DEFINITIONS:
            user, _ = CustomUser.objects.update_or_create(
                username=item["username"],
                defaults={
                    "email": item["email"],
                    "is_job_seeker": True,
                    "is_employer": False,
                    "is_active": True,
                },
            )
            user.set_password(password)
            user.save(update_fields=["password"])

            job_seeker, _ = JobSeeker.objects.update_or_create(
                user=user,
                defaults={
                    "skills": item["skills"],
                    "experience": item["experience"],
                    "education": item["education"],
                },
            )
            job_seekers[item["username"]] = job_seeker
        return job_seekers

    def _seed_jobs(self, categories, employers):
        jobs = {}
        for item in JOB_DEFINITIONS:
            deadline = date.today() + timedelta(days=item["deadline_in_days"])
            job, _ = Job.objects.update_or_create(
                title=item["title"],
                employer=employers[item["employer_username"]],
                defaults={
                    "category": categories[item["category_name"]],
                    "description": item["description"],
                    "requirements": item["requirements"],
                    "location": item["location"],
                    "salary": item["salary"],
                    "job_type": item["job_type"],
                    "deadline": deadline,
                    "is_active": True,
                },
            )
            jobs[item["key"]] = job
        return jobs

    def _seed_applications(self, jobs, job_seekers):
        for item in APPLICATION_DEFINITIONS:
            Application.objects.update_or_create(
                job=jobs[item["job_key"]],
                job_seeker=job_seekers[item["job_seeker_username"]],
                defaults={
                    "status": item["status"],
                    "cover_letter": item["cover_letter"],
                },
            )