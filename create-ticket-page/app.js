const SUPABASE_URL = '';
const SUPABASE_KEY = ''; 

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Departments of TUD 
const departments = [
  "Computer Science and Statistics",
  "Engineering",
  "Mathematics",
  "Physics",
  "Chemistry",
  "Biochemistry and Immunology",
  "Medicine",
  "Nursing and Midwifery",
  "Pharmacy and Pharmaceutical Sciences",
  "Dentistry",
  "Business School",
  "Law",
  "Psychology",
  "Education",
  "Social Sciences"
];


// Dropdown 
function loadDepartments() {
  const dropdown = document.getElementById("department");

  for (let i = 0; i < departments.length; i++) {
    const option = document.createElement("option");
    option.value = departments[i];
    option.textContent = departments[i];
    dropdown.appendChild(option);
  }
}

loadDepartments();


// Form submission
document.getElementById("ticketForm").addEventListener("submit", async function(e) {
  e.preventDefault();

  const title = document.getElementById("title").value;
  const description = document.getElementById("description").value;
  const priority = document.getElementById("priority").value;
  const department = document.getElementById("department").value;

  if (title === "" || description === "" || department === "") {
    alert("Please fill all fields");
    return;
  }

  const response = await supabaseClient
    .from("Tickets")
    .insert([
      {
        title: title,
        description: description,
        priority: priority,
        department: department   
      }
    ]);

  if (response.error) {
    console.log(response.error);
    alert("Error submitting ticket");
  } else {
    alert("Ticket submitted!");
    document.getElementById("ticketForm").reset();
  }
});