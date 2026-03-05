Let's create a high level plan in the plans folder.
The plan should stay short and focus on the high level API changes, and business logic.
Do not output detailed implementations (e.g. method bodies) into the plan.

Some code-level concerns that the plan should discuss:

1. How does the database model look like? This should be detailed SQL DDL statements.
2. How does the domain model look like? 
   This should be detailed and can have all the java record, sealed interface and enum definitions. 
3. How does the API model look like? This should be detailed (e.g. using json (pseudo) examples with some comments).
4. High level: Which components are created, what are their responsibilities, and where are they placed?
5. High level: Which components need major modifications, what are their new responsibilities / changes? 

All changes should follow existing patterns (where possible). Focus on correctness, clarity and simplicity.
Make sure to ask clarifying questions instead of making assumptions.